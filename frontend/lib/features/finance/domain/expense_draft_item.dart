import 'package:flutter/foundation.dart';
import 'package:rijiki/core/enums/expense_type.dart';

@immutable
class ExpenseDraftItem {
  const ExpenseDraftItem({
    required this.id,
    required this.expenseType,
    required this.itemName,
    required this.amount,
    required this.transactionDate,
    this.quantity,
    this.unit,
    this.vendorName,
    this.confidence = 1,
    this.needsReview = false,
  });
  final String id;
  final ExpenseType expenseType;
  final String itemName;
  final double amount;
  final DateTime transactionDate;
  final double? quantity;
  final String? unit;
  final String? vendorName;
  final double confidence;
  final bool needsReview;

  ExpenseDraftItem copyWith({
    ExpenseType? expenseType,
    String? itemName,
    double? amount,
    DateTime? transactionDate,
    double? quantity,
    bool clearQuantity = false,
    String? unit,
    String? vendorName,
    bool? needsReview,
  }) {
    return ExpenseDraftItem(
      id: id,
      expenseType: expenseType ?? this.expenseType,
      itemName: itemName ?? this.itemName,
      amount: amount ?? this.amount,
      transactionDate: transactionDate ?? this.transactionDate,
      quantity: clearQuantity ? null : (quantity ?? this.quantity),
      unit: unit == null ? this.unit : (unit.isEmpty ? null : unit),
      vendorName: vendorName == null
          ? this.vendorName
          : (vendorName.isEmpty ? null : vendorName),
      confidence: confidence,
      needsReview: needsReview ?? this.needsReview,
    );
  }
}
