import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:rijiki/core/network/api_client.dart';
import 'package:rijiki/core/storage/token_storage.dart';
import 'package:rijiki/core/enums/expense_type.dart';
import 'package:rijiki/features/finance/data/finance_repository_impl.dart';
import 'package:rijiki/features/finance/domain/expense_draft.dart';
import 'package:rijiki/features/finance/domain/finance_export.dart';
import 'package:rijiki/features/finance/domain/finance_summary.dart';
import 'package:rijiki/features/finance/domain/financial_transaction.dart';
import 'package:rijiki/features/finance/domain/transaction_filter.dart';
import 'package:rijiki/features/owner_dashboard/data/remote_dashboard_repository.dart';
import 'package:rijiki/features/owner_dashboard/domain/dashboard_summary.dart';
import 'package:rijiki/core/enums/order_status.dart';

/// TokenStorage yang selalu punya token, supaya ApiClient tidak menyentuh
/// secure storage saat tes.
class _FakeTokens extends TokenStorage {
  @override
  Future<String?> readAccessToken() async => 'token-tes';

  @override
  Future<String?> readRefreshToken() async => 'refresh-tes';
}

FinanceRepositoryImpl _financeRepo(Future<http.Response> Function(http.Request) handler) {
  return FinanceRepositoryImpl(
    api: ApiClient(
      baseUrl: 'https://contoh.test',
      tokenStorage: _FakeTokens(),
      client: MockClient(handler),
    ),
  );
}

void main() {
  group('FinanceRepositoryImpl', () {
    test('fetchSummary memetakan angka, grafik, dan pengeluaran per tipe', () async {
      late Uri captured;
      final repo = _financeRepo((request) async {
        captured = request.url;
        return http.Response(
          jsonEncode({
            'period': 'month',
            'income': 250000,
            'expense': 166000,
            'previous_income': 90000,
            'series': [
              {'label': 'Mg 1', 'amount': 0},
              {'label': 'Mg 2', 'amount': 250000},
            ],
            'expense_by_type': {
              'material': 106000,
              'equipment': 60000,
              'external_service': 0,
              'other': 0,
            },
          }),
          200,
          headers: {'content-type': 'application/json'},
        );
      });

      final summary = await repo.fetchSummary(FinancePeriod.month);

      expect(captured.path, '/api/finance/summary');
      expect(captured.queryParameters['period'], 'month');
      expect(summary.income, 250000);
      expect(summary.expense, 166000);
      expect(summary.previousIncome, 90000);
      expect(summary.series.map((p) => p.amount), [0, 250000]);
      expect(summary.expenseByType[ExpenseType.material], 106000);
      expect(summary.expenseByType[ExpenseType.equipment], 60000);
    });

    test('fetchTransactions memetakan metode pembayaran dan sumber input', () async {
      late Uri captured;
      final repo = _financeRepo((request) async {
        captured = request.url;
        return http.Response(
          jsonEncode({
            'items': [
              {
                'id': 'tx-1',
                'type': 'income',
                'expense_type': null,
                'category': 'order_payment',
                'amount': 33000,
                'description': null,
                'related_order_id': 'order-1',
                'transaction_date': '2026-11-18',
                'item_name': 'Pembayaran order RJK-1118-013',
                'quantity': null,
                'unit': null,
                'vendor_name': null,
                'input_source': 'manual',
                'receipt_image_url': null,
                'payment_method': 'cash',
              },
              {
                'id': 'tx-2',
                'type': 'expense',
                'expense_type': 'material',
                'category': null,
                'amount': 45000,
                'description': null,
                'related_order_id': null,
                'transaction_date': '2026-11-18',
                'item_name': 'Sabun',
                'quantity': 2,
                'unit': 'botol',
                'vendor_name': 'Toko Maju',
                'input_source': 'ai',
                'receipt_image_url': 'receipts/u/x.jpg',
                'payment_method': null,
              },
            ],
            'total': 2,
            'income': 33000,
            'expense': 45000,
          }),
          200,
          headers: {'content-type': 'application/json'},
        );
      });

      final rows = await repo.fetchTransactions(
        TransactionFilter(
          type: TransactionTypeFilter.expense,
          expenseType: ExpenseType.material,
          start: DateTime(2026, 11, 1),
          end: DateTime(2026, 11, 30),
        ),
      );

      expect(captured.queryParameters, {
        'type': 'expense',
        'expense_type': 'material',
        'start_date': '2026-11-01',
        'end_date': '2026-11-30',
        'page': '1',
        'limit': '50',
      });
      expect(rows.first.paymentMethod, 'cash');
      expect(rows.first.isIncome, isTrue);
      expect(rows.last.inputSource, InputSource.ai);
      expect(rows.last.expenseType, ExpenseType.material);
      expect(rows.last.quantity, 2);
      expect(rows.last.receiptImageUrl, 'receipts/u/x.jpg');
    });

    test('parseExpense memetakan draft, warning, dan penanda review', () async {
      late http.Request captured;
      final repo = _financeRepo((request) async {
        captured = request;
        return http.Response(
          jsonEncode({
            'input_id': 'input-1',
            'status': 'draft',
            'warnings': ['receipt_total_mismatch'],
            'items': [
              {
                'id': 'input-1-1',
                'expense_type': 'material',
                'item_name': 'Sabun',
                'amount': 45000,
                'transaction_date': '2026-11-18',
                'quantity': 2,
                'unit': 'botol',
                'vendor_name': 'Toko Maju',
                'confidence': 0.95,
                'needs_review': false,
              },
              {
                'id': 'input-1-2',
                'expense_type': 'other',
                'item_name': 'Entah',
                'amount': 0,
                'transaction_date': '2026-11-18',
                'quantity': null,
                'unit': null,
                'vendor_name': null,
                'confidence': 0.4,
                'needs_review': true,
              },
            ],
          }),
          200,
          headers: {'content-type': 'application/json'},
        );
      });

      final draft = await repo.parseExpense(
        text: 'beli sabun 2 botol 45rb',
        date: DateTime(2026, 11, 18),
      );

      expect(captured.url.path, '/api/finance/expenses/ai-parse');
      expect(captured.headers['content-type'], contains('multipart/form-data'));
      expect(captured.body, contains('beli sabun 2 botol 45rb'));
      expect(draft.inputId, 'input-1');
      expect(draft.status, ExpenseDraftStatus.draft);
      expect(draft.warnings, [ExpenseDraftWarning.receiptTotalMismatch]);
      expect(draft.items.first.expenseType, ExpenseType.material);
      expect(draft.items.last.needsReview, isTrue);
      expect(draft.items.last.amount, 0);
    });

    test('exportTransactions mengembalikan isi berkas dan nama dari backend', () async {
      final repo = _financeRepo((request) async {
        expect(request.url.path, '/api/finance/export');
        expect(request.url.queryParameters['expense_type'], 'material');
        return http.Response.bytes(
          utf8.encode('PK-isi-xlsx'),
          200,
          headers: {
            'content-type':
                'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet',
            'content-disposition':
                'attachment; filename="keuangan-rijiki_2026-11-01_2026-11-30_material.xlsx"',
            'x-transaction-count': '3',
          },
        );
      });

      final result = await repo.exportTransactions(
        FinanceExportQuery(
          start: DateTime(2026, 11, 1),
          end: DateTime(2026, 11, 30),
          expenseType: ExpenseType.material,
        ),
      );

      expect(result.fileName, 'keuangan-rijiki_2026-11-01_2026-11-30_material.xlsx');
      expect(result.transactionCount, 3);
      expect(utf8.decode(result.bytes!), 'PK-isi-xlsx');
    });
  });

  group('RemoteDashboardRepository', () {
    test('fetchSummary memetakan ringkasan dan grafik', () async {
      final repo = RemoteDashboardRepository(
        api: ApiClient(
          baseUrl: 'https://contoh.test',
          tokenStorage: _FakeTokens(),
          client: MockClient((request) async {
            expect(request.url.path, '/api/management/analytics/dashboard');
            expect(request.url.queryParameters['period'], 'week');
            return http.Response(
              jsonEncode({
                'period': 'week',
                'income': 1200000,
                'expense': 400000,
                'previous_income': 900000,
                'active_orders': 8,
                'series': [
                  {'label': 'Sen', 'amount': 500000},
                  {'label': 'Sel', 'amount': 700000},
                ],
              }),
              200,
              headers: {'content-type': 'application/json'},
            );
          }),
        ),
      );

      final summary = await repo.fetchSummary(DashboardPeriod.week);

      expect(summary.income, 1200000);
      expect(summary.expense, 400000);
      expect(summary.profit, 800000);
      expect(summary.activeOrders, 8);
      expect(summary.series.map((p) => p.label), ['Sen', 'Sel']);
      expect(summary.incomeChangePct, closeTo(33.333, 0.01));
    });

    test('fetchRecentOrders memetakan nama pelanggan, jumlah sepatu, dan status', () async {
      final repo = RemoteDashboardRepository(
        api: ApiClient(
          baseUrl: 'https://contoh.test',
          tokenStorage: _FakeTokens(),
          client: MockClient((request) async {
            expect(request.url.queryParameters['limit'], '5');
            return http.Response(
              jsonEncode({
                'items': [
                  {
                    'id': 'order-1',
                    'order_number': 'RJK-1118-013',
                    'customer_name': 'Jexlyn',
                    'item_count': 2,
                    'total': 33000,
                    'status': 'cleaning',
                    'created_at': '2026-11-18T07:08:59Z',
                  },
                ],
              }),
              200,
              headers: {'content-type': 'application/json'},
            );
          }),
        ),
      );

      final orders = await repo.fetchRecentOrders();

      expect(orders.single.orderNumber, 'RJK-1118-013');
      expect(orders.single.customerName, 'Jexlyn');
      expect(orders.single.itemCount, 2);
      expect(orders.single.status, OrderStatus.cleaning);
    });
  });
}
