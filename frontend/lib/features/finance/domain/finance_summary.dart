import 'package:flutter/foundation.dart';
import 'package:rijiki/core/enums/expense_type.dart';

enum FinancePeriod {
  today,
  week,
  month;

  String get label => switch (this) {
    FinancePeriod.today => 'Hari ini',
    FinancePeriod.week => 'Minggu ini',
    FinancePeriod.month => 'Bulan ini',
  };

  String get compareLabel => switch (this) {
    FinancePeriod.today => 'vs kemarin',
    FinancePeriod.week => 'vs minggu lalu',
    FinancePeriod.month => 'vs bulan lalu',
  };
}

@immutable
class FinancePoint {
  const FinancePoint({required this.label, required this.amount});

  final String label;
  final double amount;
}

@immutable
class FinanceSummary {
  const FinanceSummary({
    required this.period,
    required this.income,
    required this.expense,
    required this.previousIncome,
    required this.series,
    required this.expenseByType,
  });

  final FinancePeriod period;
  final double income;
  final double expense;
  final double previousIncome;
  final List<FinancePoint> series;
  final Map<ExpenseType, double> expenseByType;

  double get profit => income - expense;
  double? get incomeChangePct {
    if (previousIncome <= 0) return null;
    return (income - previousIncome) / previousIncome * 100;
  }
  double? get profitMarginPct {
    if (income <= 0) return null;
    return profit / income * 100;
  }
}
