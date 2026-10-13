import 'package:flutter/foundation.dart';
import 'package:rijiki/core/enums/expense_type.dart';

enum TransactionTypeFilter {
  all,
  income,
  expense;

  String get label => switch (this) {
    TransactionTypeFilter.all => 'Semua',
    TransactionTypeFilter.income => 'Pemasukan',
    TransactionTypeFilter.expense => 'Pengeluaran',
  };
}

@immutable
class TransactionFilter {
  const TransactionFilter({
    this.type = TransactionTypeFilter.all,
    this.expenseType,
    this.start,
    this.end,
  });

  final TransactionTypeFilter type;
  final ExpenseType? expenseType;
  final DateTime? start;
  final DateTime? end;

  bool get hasRange => start != null && end != null;

  bool get isDefault =>
      type == TransactionTypeFilter.all &&
      expenseType == null &&
      !hasRange;

  TransactionFilter copyWith({
    TransactionTypeFilter? type,
    ExpenseType? expenseType,
    bool clearExpenseType = false,
    DateTime? start,
    DateTime? end,
    bool clearRange = false,
  }) {
    return TransactionFilter(
      type: type ?? this.type,
      expenseType: clearExpenseType ? null : (expenseType ?? this.expenseType),
      start: clearRange ? null : (start ?? this.start),
      end: clearRange ? null : (end ?? this.end),
    );
  }
}
