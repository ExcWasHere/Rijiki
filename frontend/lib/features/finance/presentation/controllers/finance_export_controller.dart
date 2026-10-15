import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:rijiki/app/providers.dart';
import 'package:rijiki/features/finance/domain/finance_export.dart';
import 'package:rijiki/features/finance/domain/transaction_filter.dart';

@immutable
class ExportPreview {
  const ExportPreview({
    required this.count,
    required this.income,
    required this.expense,
  });

  final int count;
  final double income;
  final double expense;
}

final exportPreviewProvider = FutureProvider.autoDispose
    .family<ExportPreview, FinanceExportQuery>((ref, query) async {
      final rows = await ref
          .watch(financeRepositoryProvider)
          .fetchTransactions(
            TransactionFilter(
              type: query.expenseType == null
                  ? TransactionTypeFilter.all
                  : TransactionTypeFilter.expense,
              expenseType: query.expenseType,
              start: query.start,
              end: query.end,
            ),
          );

      var income = 0.0;
      var expense = 0.0;
      for (final t in rows) {
        if (t.isIncome) {
          income += t.amount;
        } else {
          expense += t.amount;
        }
      }
      return ExportPreview(count: rows.length, income: income, expense: expense);
    });

enum ExportStatus { idle, exporting, success, failure }

@immutable
class ExportState {
  const ExportState({
    this.status = ExportStatus.idle,
    this.result,
    this.errorMessage,
  });

  final ExportStatus status;
  final FinanceExportResult? result;
  final String? errorMessage;

  bool get isExporting => status == ExportStatus.exporting;
}

class ExportNotifier extends Notifier<ExportState> {
  @override
  ExportState build() => const ExportState();

  Future<void> run(FinanceExportQuery query) async {
    if (state.isExporting) return;
    state = const ExportState(status: ExportStatus.exporting);
    try {
      final result = await ref
          .read(financeRepositoryProvider)
          .exportTransactions(query);
      if (!ref.mounted) return;
      state = ExportState(status: ExportStatus.success, result: result);
    } catch (_) {
      if (!ref.mounted) return;
      state = const ExportState(
        status: ExportStatus.failure,
        errorMessage: 'Ekspor gagal. Coba lagi ya.',
      );
    }
  }

  void reset() => state = const ExportState();
}

final exportActionProvider =
    NotifierProvider.autoDispose<ExportNotifier, ExportState>(
      ExportNotifier.new,
    );
