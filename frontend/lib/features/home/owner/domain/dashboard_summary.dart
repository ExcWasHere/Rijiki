import 'package:flutter/foundation.dart';

enum DashboardPeriod {
  today,
  week,
  month;

  String get label => switch (this) {
    DashboardPeriod.today => 'Hari ini',
    DashboardPeriod.week => 'Minggu ini',
    DashboardPeriod.month => 'Bulan ini',
  };

  String get compareLabel => switch (this) {
    DashboardPeriod.today => 'vs kemarin',
    DashboardPeriod.week => 'vs minggu lalu',
    DashboardPeriod.month => 'vs bulan lalu',
  };
}

@immutable
class RevenuePoint {
  const RevenuePoint({required this.label, required this.amount});

  final String label;
  final double amount;
}

@immutable
class DashboardSummary {
  const DashboardSummary({
    required this.period,
    required this.income,
    required this.expense,
    required this.previousIncome,
    required this.activeOrders,
    required this.series,
  });

  final DashboardPeriod period;
  final double income;
  final double expense;
  final double previousIncome;
  final int activeOrders;
  final List<RevenuePoint> series;

  double get profit => income - expense;
  double? get incomeChangePct {
    if (previousIncome <= 0) return null;
    return (income - previousIncome) / previousIncome * 100;
  }
}
