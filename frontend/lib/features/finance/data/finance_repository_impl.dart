import 'package:rijiki/core/enums/expense_type.dart';
import 'package:rijiki/core/error/app_exception.dart';
import 'package:rijiki/core/error/failure_mapper.dart';
import 'package:rijiki/core/network/api_client.dart';
import 'package:rijiki/core/network/api_endpoint.dart';
import 'package:rijiki/features/finance/domain/expense_draft.dart';
import 'package:rijiki/features/finance/domain/expense_draft_item.dart';
import 'package:rijiki/features/finance/domain/finance_export.dart';
import 'package:rijiki/features/finance/domain/finance_repository.dart';
import 'package:rijiki/features/finance/domain/finance_summary.dart';
import 'package:rijiki/features/finance/domain/financial_transaction.dart';
import 'package:rijiki/features/finance/domain/transaction_filter.dart';

/// Satu halaman daftar transaksi beserta total baris yang cocok dengan filter.
class FinanceTransactionPage {
  const FinanceTransactionPage({
    required this.items,
    required this.total,
    required this.page,
    required this.limit,
  });

  final List<FinancialTransaction> items;

  /// Total transaksi di server untuk filter yang sama (bukan panjang [items]).
  final int total;
  final int page;
  final int limit;

  bool get hasMore => items.isNotEmpty && page * limit < total;
}

/// Keuangan dari backend (`/api/finance`), izin `manage_finance`.
/// Angka ringkasan, rekap, pemasukan manual, input pengeluaran AI, dan ekspor
/// xlsx semuanya dihitung server supaya layar Keuangan dan dashboard Owner
/// memakai sumber yang sama.
class FinanceRepositoryImpl implements FinanceRepository {
  FinanceRepositoryImpl({required this.api});

  /// Ukuran halaman bawaan daftar transaksi.
  static const int defaultPageSize = 50;

  final ApiClient api;

  @override
  Future<FinanceSummary> fetchSummary(FinancePeriod period) async {
    try {
      final json = await api.get(
        Uri(
          path: ApiEndpoints.financeSummary,
          queryParameters: {'period': period.name},
        ).toString(),
        auth: true,
      );
      final expenseByType = <ExpenseType, double>{};
      final raw = json['expense_by_type'] as Map<String, dynamic>? ?? const {};
      for (final entry in raw.entries) {
        final type = ExpenseType.tryParse(entry.key);
        if (type != null) {
          expenseByType[type] = (entry.value as num? ?? 0).toDouble();
        }
      }

      return FinanceSummary(
        period: period,
        income: _double(json['income']),
        expense: _double(json['expense']),
        previousIncome: _double(json['previous_income']),
        series: [
          for (final point in json['series'] as List<dynamic>? ?? const [])
            FinancePoint(
              label: (point as Map<String, dynamic>)['label'] as String? ?? '',
              amount: _double(point['amount']),
            ),
        ],
        expenseByType: expenseByType,
      );
    } on AppException catch (e) {
      throw failureFromException(e);
    }
  }

  @override
  Future<List<FinancialTransaction>> fetchTransactions(
    TransactionFilter filter,
  ) async {
    // Kontrak lama: seluruh baris yang cocok (dipakai pratinjau ekspor).
    final all = <FinancialTransaction>[];
    var page = 1;
    while (true) {
      final result = await fetchTransactionPage(
        filter,
        page: page,
        limit: defaultPageSize,
      );
      all.addAll(result.items);
      if (result.items.isEmpty ||
          all.length >= result.total ||
          !result.hasMore) {
        break;
      }
      page++;
    }
    return all;
  }

  /// Satu halaman transaksi. Kontrak backend:
  /// `{ "items": [...], "total": int, "page": int, "limit": int }`.
  Future<FinanceTransactionPage> fetchTransactionPage(
    TransactionFilter filter, {
    int page = 1,
    int limit = defaultPageSize,
  }) async {
    final query = <String, String>{
      'page': '$page',
      'limit': '$limit',
      if (filter.type != TransactionTypeFilter.all) 'type': filter.type.name,
      if (filter.expenseType != null) 'expense_type': filter.expenseType!.value,
      if (filter.hasRange) ...{
        'start_date': _ymd(filter.start!),
        'end_date': _ymd(filter.end!),
      },
    };

    try {
      final json = await api.get(
        Uri(
          path: ApiEndpoints.financeTransactions,
          queryParameters: query,
        ).toString(),
        auth: true,
      );
      final items = [
        for (final raw in json['items'] as List<dynamic>? ?? const [])
          _transactionFromJson(raw as Map<String, dynamic>),
      ];
      return FinanceTransactionPage(
        items: items,
        total: (json['total'] as num?)?.toInt() ?? items.length,
        page: (json['page'] as num?)?.toInt() ?? page,
        limit: (json['limit'] as num?)?.toInt() ?? limit,
      );
    } on AppException catch (e) {
      throw failureFromException(e);
    }
  }

  @override
  Future<ExpenseDraft> parseExpense({
    String? text,
    String? receiptPath,
    required DateTime date,
  }) async {
    try {
      final json = await api.postMultipart(
        ApiEndpoints.financeExpenseAiParse,
        auth: true,
        fields: {
          if (text != null && text.trim().isNotEmpty) 'input_text': text.trim(),
          'transaction_date': _ymd(date),
        },
        fileField: receiptPath == null ? null : 'image',
        filePath: receiptPath,
      );

      final warnings = <ExpenseDraftWarning>[
        for (final raw in json['warnings'] as List<dynamic>? ?? const [])
          if (raw == 'ai_unavailable')
            ExpenseDraftWarning.aiUnavailable
          else if (raw == 'receipt_total_mismatch')
            ExpenseDraftWarning.receiptTotalMismatch,
      ];

      return ExpenseDraft(
        inputId: json['input_id'] as String,
        status: json['status'] == 'failed'
            ? ExpenseDraftStatus.failed
            : ExpenseDraftStatus.draft,
        warnings: warnings,
        items: [
          for (final raw in json['items'] as List<dynamic>? ?? const [])
            _draftItemFromJson(raw as Map<String, dynamic>, date),
        ],
      );
    } on AppException catch (e) {
      throw failureFromException(e);
    }
  }

  @override
  Future<List<FinancialTransaction>> confirmExpenseDraft(
    String inputId,
    List<ExpenseDraftItem> items,
  ) async {
    try {
      final json = await api.post(
        ApiEndpoints.financeExpenseAiConfirm(inputId),
        auth: true,
        body: {
          'items': [
            for (final item in items)
              {
                'expense_type': item.expenseType.value,
                'item_name': item.itemName.trim().isEmpty
                    ? 'Pengeluaran'
                    : item.itemName.trim(),
                'amount': item.amount,
                'transaction_date': _ymd(item.transactionDate),
                'quantity': item.quantity,
                'unit': item.unit,
                'vendor_name': item.vendorName,
              },
          ],
        },
      );
      // Backend membalas { items: [...] } berisi transaksi yang dibuat.
      return [
        for (final row in json['items'] as List<dynamic>? ?? const [])
          _transactionFromJson(row as Map<String, dynamic>),
      ];
    } on AppException catch (e) {
      throw failureFromException(e);
    }
  }

  @override
  Future<void> cancelExpenseDraft(String inputId) async {
    try {
      await api.delete(ApiEndpoints.financeExpenseAiDiscard(inputId), auth: true);
    } on AppException catch (e) {
      throw failureFromException(e);
    }
  }

  @override
  Future<FinancialTransaction> addIncome({
    required String name,
    required double amount,
    required DateTime date,
    String? description,
  }) async {
    try {
      final json = await api.post(
        ApiEndpoints.financeTransactions,
        auth: true,
        body: {
          'type': 'income',
          'amount': amount,
          'transaction_date': _ymd(date),
          'item_name': name.trim(),
          if (description != null && description.trim().isNotEmpty)
            'description': description.trim(),
        },
      );
      return _transactionFromJson(json);
    } on AppException catch (e) {
      throw failureFromException(e);
    }
  }

  @override
  Future<FinanceExportResult> exportTransactions(
    FinanceExportQuery query,
  ) async {
    try {
      final file = await api.getFile(
        Uri(
          path: ApiEndpoints.financeExport,
          queryParameters: {
            'start_date': _ymd(query.start),
            'end_date': _ymd(query.end),
            if (query.expenseType != null) 'expense_type': query.expenseType!.value,
          },
        ).toString(),
        auth: true,
      );
      final count = int.tryParse(file.headers['x-transaction-count'] ?? '') ?? 0;
      return FinanceExportResult(
        fileName: _fileNameFrom(file.headers['content-disposition']) ??
            'keuangan-rijiki_${_ymd(query.start)}_${_ymd(query.end)}.xlsx',
        transactionCount: count,
        bytes: file.bytes,
      );
    } on AppException catch (e) {
      throw failureFromException(e);
    }
  }

  static String? _fileNameFrom(String? disposition) {
    if (disposition == null) return null;
    final match = RegExp(r'filename="?([^";]+)"?').firstMatch(disposition);
    return match?.group(1);
  }

  static double _double(Object? value) => (value as num? ?? 0).toDouble();

  static String _ymd(DateTime date) =>
      '${date.year.toString().padLeft(4, '0')}-'
      '${date.month.toString().padLeft(2, '0')}-'
      '${date.day.toString().padLeft(2, '0')}';

  static FinancialTransaction _transactionFromJson(Map<String, dynamic> json) {
    return FinancialTransaction(
      id: json['id'] as String,
      type: json['type'] == 'income'
          ? TransactionType.income
          : TransactionType.expense,
      expenseType: ExpenseType.tryParse(json['expense_type'] as String? ?? ''),
      category: json['category'] as String?,
      itemName: json['item_name'] as String?,
      quantity: (json['quantity'] as num?)?.toDouble(),
      unit: json['unit'] as String?,
      vendorName: json['vendor_name'] as String?,
      amount: _double(json['amount']),
      description: json['description'] as String?,
      relatedOrderId: json['related_order_id'] as String?,
      inputSource: json['input_source'] == 'ai'
          ? InputSource.ai
          : InputSource.manual,
      receiptImageUrl: json['receipt_image_url'] as String?,
      paymentMethod: json['payment_method'] as String?,
      transactionDate:
          DateTime.tryParse(json['transaction_date'] as String? ?? '') ??
          DateTime.now(),
    );
  }

  static ExpenseDraftItem _draftItemFromJson(
    Map<String, dynamic> json,
    DateTime fallbackDate,
  ) {
    return ExpenseDraftItem(
      id: json['id'] as String,
      expenseType: ExpenseType.tryParse(json['expense_type'] as String? ?? '') ??
          ExpenseType.other,
      itemName: json['item_name'] as String? ?? '',
      amount: _double(json['amount']),
      transactionDate:
          DateTime.tryParse(json['transaction_date'] as String? ?? '') ??
          fallbackDate,
      quantity: (json['quantity'] as num?)?.toDouble(),
      unit: json['unit'] as String?,
      vendorName: json['vendor_name'] as String?,
      confidence: _double(json['confidence']),
      needsReview: json['needs_review'] as bool? ?? false,
    );
  }
}

/// Mengambil satu halaman transaksi dari [repository].
///
/// Implementasi API mendukung paginasi penuh. Implementasi lain (mis. fake di
/// test) mengembalikan semua barisnya sebagai satu halaman.
Future<FinanceTransactionPage> fetchFinanceTransactionPage(
  FinanceRepository repository,
  TransactionFilter filter, {
  int page = 1,
  int limit = FinanceRepositoryImpl.defaultPageSize,
}) async {
  if (repository is FinanceRepositoryImpl) {
    return repository.fetchTransactionPage(filter, page: page, limit: limit);
  }
  final items = await repository.fetchTransactions(filter);
  return FinanceTransactionPage(
    items: items,
    total: items.length,
    page: 1,
    limit: items.isEmpty ? limit : items.length,
  );
}
