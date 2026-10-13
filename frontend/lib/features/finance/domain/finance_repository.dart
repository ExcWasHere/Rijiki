import 'package:rijiki/features/finance/domain/finance_summary.dart';
import 'package:rijiki/features/finance/domain/financial_transaction.dart';
import 'package:rijiki/features/finance/domain/transaction_filter.dart';

abstract class FinanceRepository {
  Future<FinanceSummary> fetchSummary(FinancePeriod period);
  Future<List<FinancialTransaction>> fetchTransactions(
    TransactionFilter filter,
  );
}
