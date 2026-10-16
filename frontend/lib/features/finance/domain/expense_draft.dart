import 'package:flutter/foundation.dart';
import 'package:rijiki/features/finance/domain/expense_draft_item.dart';

enum ExpenseDraftStatus { draft, failed }

enum ExpenseDraftWarning { aiUnavailable, receiptTotalMismatch }

@immutable
class ExpenseDraft {
  const ExpenseDraft({
    required this.inputId,
    required this.status,
    required this.items,
    this.warnings = const [],
  });

  final String inputId;
  final ExpenseDraftStatus status;
  final List<ExpenseDraftItem> items;
  final List<ExpenseDraftWarning> warnings;

  bool get isAiUnavailable => warnings.contains(ExpenseDraftWarning.aiUnavailable);

  ExpenseDraft copyWith({List<ExpenseDraftItem>? items}) {
    return ExpenseDraft(
      inputId: inputId,
      status: status,
      items: items ?? this.items,
      warnings: warnings,
    );
  }
}
