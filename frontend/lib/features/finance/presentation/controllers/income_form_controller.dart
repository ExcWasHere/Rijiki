import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:rijiki/app/providers.dart';
import 'package:rijiki/features/finance/presentation/controllers/finance_controller.dart';

@immutable
class IncomeFormState {
  const IncomeFormState({this.saving = false, this.errorMessage});

  final bool saving;
  final String? errorMessage;
}

class IncomeFormNotifier extends Notifier<IncomeFormState> {
  @override
  IncomeFormState build() => const IncomeFormState();
  Future<bool> submit({
    required String name,
    required double amount,
    required DateTime date,
    String? description,
  }) async {
    state = const IncomeFormState(saving: true);
    try {
      await ref
          .read(financeRepositoryProvider)
          .addIncome(
            name: name,
            amount: amount,
            date: date,
            description: description,
          );
      if (!ref.mounted) return true;
      ref.invalidate(financeTransactionsProvider);
      ref.invalidate(financeSummaryProvider);
      state = const IncomeFormState();
      return true;
    } catch (_) {
      if (!ref.mounted) return false;
      state = const IncomeFormState(
        errorMessage: 'Gagal menyimpan pemasukan. Coba lagi ya.',
      );
      return false;
    }
  }
}

final incomeFormProvider =
    NotifierProvider.autoDispose<IncomeFormNotifier, IncomeFormState>(
      IncomeFormNotifier.new,
    );
