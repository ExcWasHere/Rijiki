import 'package:flutter/foundation.dart';
import 'package:rijiki/core/enums/expense_type.dart';

@immutable
class FinanceExportQuery {
  const FinanceExportQuery({
    required this.start,
    required this.end,
    this.expenseType,
  });

  final DateTime start;
  final DateTime end;
  final ExpenseType? expenseType;

  @override
  bool operator ==(Object other) =>
      other is FinanceExportQuery &&
      other.start == start &&
      other.end == end &&
      other.expenseType == expenseType;

  @override
  int get hashCode => Object.hash(start, end, expenseType);
}

@immutable
class FinanceExportResult {
  const FinanceExportResult({
    required this.fileName,
    required this.transactionCount,
  });

  final String fileName;
  final int transactionCount;
}
