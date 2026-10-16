import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:rijiki/app/router/route_paths.dart';
import 'package:rijiki/core/theme/app_colors.dart';
import 'package:rijiki/core/theme/app_spacing.dart';
import 'package:rijiki/features/finance/presentation/controllers/expense_ai_controller.dart';
import 'package:rijiki/features/finance/presentation/widgets/expense_input_card.dart';
import 'package:rijiki/features/finance/presentation/widgets/expense_type_legend_card.dart';

class ExpenseAiInputPage extends ConsumerStatefulWidget {
  const ExpenseAiInputPage({super.key});

  @override
  ConsumerState<ExpenseAiInputPage> createState() => _ExpenseAiInputPageState();
}

class _ExpenseAiInputPageState extends ConsumerState<ExpenseAiInputPage> {
  final TextEditingController _text = TextEditingController();

  @override
  void dispose() {
    _text.dispose();
    super.dispose();
  }

  Future<void> _pickDate() async {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final current = ref.read(expenseAiProvider).date;

    final picked = await showDatePicker(
      context: context,
      initialDate: current.isAfter(today) ? today : current,
      firstDate: DateTime(today.year - 2),
      lastDate: today,
      helpText: 'Tanggal pengeluaran',
    );
    if (picked != null) ref.read(expenseAiProvider.notifier).setDate(picked);
  }

  Future<void> _submit() async {
    FocusScope.of(context).unfocus();
    final ok = await ref.read(expenseAiProvider.notifier).parse(_text.text);
    if (!mounted) return;

    if (ok) {
      context.push(RoutePaths.ownerFinanceExpenseReview);
      return;
    }
    final message = ref.read(expenseAiProvider).errorMessage;
    if (message != null) {
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(SnackBar(content: Text(message)));
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(expenseAiProvider);
    final notifier = ref.read(expenseAiProvider.notifier);
    final parsing = state.phase == ExpenseAiPhase.parsing;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(title: const Text('Catat pengeluaran')),
      body: ListView(
        keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
        padding: const EdgeInsets.fromLTRB(
          AppSpacing.lg,
          AppSpacing.md,
          AppSpacing.lg,
          AppSpacing.xl,
        ),
        children: [
          ExpenseInputCard(
            controller: _text,
            date: state.date,
            receiptPath: state.receiptPath,
            onPickDate: _pickDate,
            onReceiptChanged: notifier.setReceipt,
            enabled: !parsing,
          ),
          const SizedBox(height: AppSpacing.md),
          ListenableBuilder(
            listenable: _text,
            builder: (context, _) {
              final hasInput =
                  _text.text.trim().isNotEmpty || state.receiptPath != null;
              return FilledButton.icon(
                onPressed: hasInput && !parsing ? _submit : null,
                icon: parsing
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: AppColors.onPrimary,
                        ),
                      )
                    : const Icon(Icons.auto_awesome_rounded, size: 20),
                label: Text(parsing ? 'AI sedang memproses...' : 'Proses dengan AI'),
              );
            },
          ),
          const SizedBox(height: AppSpacing.lg),
          const ExpenseTypeLegendCard(),
        ],
      ),
    );
  }
}
