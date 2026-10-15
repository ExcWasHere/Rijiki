import 'package:rijiki/features/finance/domain/expense_draft.dart';
import 'package:rijiki/features/finance/domain/expense_draft_item.dart';
import 'package:rijiki/features/finance/domain/finance_summary.dart';
import 'package:rijiki/features/finance/domain/financial_transaction.dart';
import 'package:rijiki/features/finance/domain/transaction_filter.dart';

abstract class FinanceRepository {
  Future<FinanceSummary> fetchSummary(FinancePeriod period);
  Future<List<FinancialTransaction>> fetchTransactions(
    TransactionFilter filter,
  );

  Future<ExpenseDraft> parseExpense({
    String? text,
    String? receiptPath,
    required DateTime date,
  });

  Future<List<FinancialTransaction>> confirmExpenseDraft(
    String inputId,
    List<ExpenseDraftItem> items,
  );

  Future<void> cancelExpenseDraft(String inputId);
  Future<FinancialTransaction> addIncome({
    required String name,
    required double amount,
    required DateTime date,
    String? description,
  });
}
