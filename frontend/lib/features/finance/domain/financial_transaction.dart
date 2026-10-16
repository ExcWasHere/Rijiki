import 'package:flutter/foundation.dart';
import 'package:rijiki/core/enums/expense_type.dart';

enum TransactionType { income, expense }
enum InputSource { manual, ai }

@immutable
class FinancialTransaction {
  const FinancialTransaction({
    required this.id,
    required this.type,
    required this.amount,
    required this.transactionDate,
    this.expenseType,
    this.category,
    this.itemName,
    this.quantity,
    this.unit,
    this.vendorName,
    this.description,
    this.relatedOrderId,
    this.inputSource = InputSource.manual,
    this.receiptImageUrl,
  });

  final String id;
  final TransactionType type;
  final ExpenseType? expenseType;
  final String? category;
  final String? itemName;
  final double? quantity;
  final String? unit;
  final String? vendorName;

  final double amount;
  final String? description;
  final String? relatedOrderId;
  final InputSource inputSource;

  final String? receiptImageUrl;
  final DateTime transactionDate;

  bool get isIncome => type == TransactionType.income;
  bool get isExpense => type == TransactionType.expense;
}
