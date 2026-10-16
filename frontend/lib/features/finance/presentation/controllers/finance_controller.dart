import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:rijiki/app/providers.dart';
import 'package:rijiki/core/enums/expense_type.dart';
import 'package:rijiki/features/finance/domain/finance_summary.dart';
import 'package:rijiki/features/finance/domain/financial_transaction.dart';
import 'package:rijiki/features/finance/domain/transaction_filter.dart';

class FinancePeriodNotifier extends Notifier<FinancePeriod> {
  @override
  FinancePeriod build() => FinancePeriod.month;

  void select(FinancePeriod period) => state = period;
}

final financePeriodProvider =
    NotifierProvider<FinancePeriodNotifier, FinancePeriod>(
      FinancePeriodNotifier.new,
    );

final financeSummaryProvider = FutureProvider.autoDispose<FinanceSummary>((
  ref,
) {
  final period = ref.watch(financePeriodProvider);
  return ref.watch(financeRepositoryProvider).fetchSummary(period);
});

Future<void> refreshFinance(WidgetRef ref) async {
  ref.invalidate(financeSummaryProvider);
  await ref.read(financeSummaryProvider.future);
}

class TransactionFilterNotifier extends Notifier<TransactionFilter> {
  @override
  TransactionFilter build() => const TransactionFilter();
  void selectType(TransactionTypeFilter type) {
    state = state.copyWith(type: type, clearExpenseType: true);
  }
  void selectExpenseType(ExpenseType? type) {
    state = type == null
        ? state.copyWith(clearExpenseType: true)
        : state.copyWith(expenseType: type);
  }

  void setRange(DateTime start, DateTime end) {
    state = state.copyWith(start: start, end: end);
  }

  void clearRange() => state = state.copyWith(clearRange: true);

  void reset() => state = const TransactionFilter();
}

final transactionFilterProvider =
    NotifierProvider<TransactionFilterNotifier, TransactionFilter>(
      TransactionFilterNotifier.new,
    );

final financeTransactionsProvider =
    FutureProvider.autoDispose<List<FinancialTransaction>>((ref) {
      final filter = ref.watch(transactionFilterProvider);
      return ref.watch(financeRepositoryProvider).fetchTransactions(filter);
    });

Future<void> refreshTransactions(WidgetRef ref) async {
  ref.invalidate(financeTransactionsProvider);
  await ref.read(financeTransactionsProvider.future);
}
