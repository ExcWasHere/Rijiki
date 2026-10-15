import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:rijiki/app/providers.dart';
import 'package:rijiki/core/enums/expense_type.dart';
import 'package:rijiki/features/finance/domain/expense_draft.dart';
import 'package:rijiki/features/finance/domain/expense_draft_item.dart';
import 'package:rijiki/features/finance/presentation/controllers/finance_controller.dart';

enum ExpenseAiPhase { idle, parsing, review, saving }

@immutable
class ExpenseAiState {
  const ExpenseAiState({
    required this.date,
    this.phase = ExpenseAiPhase.idle,
    this.receiptPath,
    this.draft,
    this.errorMessage,
  });

  final ExpenseAiPhase phase;
  final DateTime date;
  final String? receiptPath;
  final ExpenseDraft? draft;
  final String? errorMessage;

  List<ExpenseDraftItem> get items => draft?.items ?? const [];
  bool get isBusy =>
      phase == ExpenseAiPhase.parsing || phase == ExpenseAiPhase.saving;

  double get total => items.fold(0, (sum, item) => sum + item.amount);
  int get pendingReviewCount => items.where((i) => i.needsReview).length;
  int get missingAmountCount => items.where((i) => i.amount <= 0).length;

  bool get canSave =>
      draft != null &&
      items.isNotEmpty &&
      pendingReviewCount == 0 &&
      missingAmountCount == 0 &&
      !isBusy;

  ExpenseAiState copyWith({
    ExpenseAiPhase? phase,
    DateTime? date,
    String? receiptPath,
    bool clearReceipt = false,
    ExpenseDraft? draft,
    bool clearDraft = false,
    String? errorMessage,
    bool clearError = false,
  }) {
    return ExpenseAiState(
      phase: phase ?? this.phase,
      date: date ?? this.date,
      receiptPath: clearReceipt ? null : (receiptPath ?? this.receiptPath),
      draft: clearDraft ? null : (draft ?? this.draft),
      errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
    );
  }
}

class ExpenseAiNotifier extends Notifier<ExpenseAiState> {
  @override
  ExpenseAiState build() => ExpenseAiState(date: _today());

  static DateTime _today() {
    final now = DateTime.now();
    return DateTime(now.year, now.month, now.day);
  }

  void setDate(DateTime date) => state = state.copyWith(date: date);

  void setReceipt(String? path) {
    state = path == null
        ? state.copyWith(clearReceipt: true)
        : state.copyWith(receiptPath: path);
  }
  Future<bool> parse(String text) async {
    final input = text.trim();
    if (input.isEmpty && state.receiptPath == null) {
      state = state.copyWith(
        errorMessage: 'Tulis dulu pengeluarannya atau lampirkan nota.',
      );
      return false;
    }

    state = state.copyWith(phase: ExpenseAiPhase.parsing, clearError: true);
    try {
      final draft = await ref
          .read(financeRepositoryProvider)
          .parseExpense(
            text: input.isEmpty ? null : input,
            receiptPath: state.receiptPath,
            date: state.date,
          );
      if (!ref.mounted) return false;
      state = state.copyWith(phase: ExpenseAiPhase.review, draft: draft);
      return true;
    } catch (_) {
      if (!ref.mounted) return false;
      state = state.copyWith(
        phase: ExpenseAiPhase.idle,
        errorMessage: 'Gagal memproses. Coba lagi ya.',
      );
      return false;
    }
  }

  void updateItem(ExpenseDraftItem item) {
    final draft = state.draft;
    if (draft == null) return;
    state = state.copyWith(
      draft: draft.copyWith(
        items: [for (final i in draft.items) i.id == item.id ? item : i],
      ),
    );
  }

  void removeItem(String id) {
    final draft = state.draft;
    if (draft == null) return;
    state = state.copyWith(
      draft: draft.copyWith(
        items: [
          for (final i in draft.items)
            if (i.id != id) i,
        ],
      ),
    );
  }

  void addItem() {
    final draft = state.draft;
    if (draft == null) return;
    final item = ExpenseDraftItem(
      id: 'new-${DateTime.now().microsecondsSinceEpoch}',
      expenseType: ExpenseType.other,
      itemName: '',
      amount: 0,
      transactionDate: state.date,
    );
    state = state.copyWith(draft: draft.copyWith(items: [...draft.items, item]));
  }

  Future<int?> confirm() async {
    final draft = state.draft;
    if (draft == null || !state.canSave) return null;

    state = state.copyWith(phase: ExpenseAiPhase.saving, clearError: true);
    try {
      final saved = await ref
          .read(financeRepositoryProvider)
          .confirmExpenseDraft(draft.inputId, draft.items);
      if (!ref.mounted) return saved.length;
      ref.invalidate(financeTransactionsProvider);
      ref.invalidate(financeSummaryProvider);
      return saved.length;
    } catch (_) {
      if (!ref.mounted) return null;
      state = state.copyWith(
        phase: ExpenseAiPhase.review,
        errorMessage: 'Gagal menyimpan. Coba lagi ya.',
      );
      return null;
    }
  }

  Future<void> discardDraft() async {
    final draft = state.draft;
    state = state.copyWith(phase: ExpenseAiPhase.idle, clearDraft: true);
    if (draft != null) {
      await ref.read(financeRepositoryProvider).cancelExpenseDraft(draft.inputId);
    }
  }
}

final expenseAiProvider =
    NotifierProvider.autoDispose<ExpenseAiNotifier, ExpenseAiState>(
      ExpenseAiNotifier.new,
    );
