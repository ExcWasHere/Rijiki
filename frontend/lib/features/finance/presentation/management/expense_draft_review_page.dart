import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:rijiki/app/router/route_paths.dart';
import 'package:rijiki/core/theme/app_colors.dart';
import 'package:rijiki/core/theme/app_spacing.dart';
import 'package:rijiki/core/utils/rupiah_formatter.dart';
import 'package:rijiki/features/finance/presentation/controllers/expense_ai_controller.dart';
import 'package:rijiki/features/finance/presentation/widgets/expense_draft_item_card.dart';
import 'package:rijiki/features/finance/presentation/widgets/finance_state_card.dart';
import 'package:rijiki/shared/widgets/empty_state.dart';

class ExpenseDraftReviewPage extends ConsumerWidget {
  const ExpenseDraftReviewPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(expenseAiProvider);
    final notifier = ref.read(expenseAiProvider.notifier);
    final draft = state.draft;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(title: const Text('Periksa hasil AI')),
      body: draft == null
          ? Padding(
              padding: const EdgeInsets.all(AppSpacing.lg),
              child: Center(
                child: FinanceStateCard(
                  child: EmptyState(
                    icon: Icons.auto_awesome_rounded,
                    title: 'Belum ada hasil',
                    message: 'Kembali dan ceritakan pengeluarannya dulu ya.',
                    actionLabel: 'Kembali',
                    onAction: () => context.pop(),
                  ),
                ),
              ),
            )
          : ListView(
              keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
              padding: const EdgeInsets.fromLTRB(
                AppSpacing.lg,
                AppSpacing.md,
                AppSpacing.lg,
                AppSpacing.xl,
              ),
              children: [
                if (draft.isAiUnavailable)
                  const _AiUnavailableBanner()
                else
                  _SummaryLine(
                    count: state.items.length,
                    pending: state.pendingReviewCount,
                  ),
                const SizedBox(height: AppSpacing.md),
                for (final item in state.items) ...[
                  ExpenseDraftItemCard(
                    key: ValueKey(item.id),
                    item: item,
                    canRemove: state.items.length > 1,
                    onChanged: notifier.updateItem,
                    onRemove: () => notifier.removeItem(item.id),
                  ),
                  const SizedBox(height: AppSpacing.md),
                ],
                OutlinedButton.icon(
                  onPressed: state.isBusy ? null : notifier.addItem,
                  icon: const Icon(Icons.add_rounded, size: AppSpacing.iconSm + 2),
                  label: const Text('Tambah item'),
                ),
              ],
            ),
      bottomNavigationBar: draft == null ? null : _SaveBar(state: state),
    );
  }
}

class _SummaryLine extends StatelessWidget {
  const _SummaryLine({required this.count, required this.pending});

  final int count;
  final int pending;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return Row(
      children: [
        Expanded(
          child: Text(
            '$count item ditemukan. Cek dulu sebelum disimpan.',
            style: textTheme.bodyMedium?.copyWith(
              color: AppColors.onSurfaceVariant,
            ),
          ),
        ),
        if (pending > 0)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: AppColors.warning.withValues(alpha: 0.16),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              '$pending perlu dicek',
              style: textTheme.labelMedium?.copyWith(
                color: AppColors.onSurface,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
      ],
    );
  }
}

class _AiUnavailableBanner extends StatelessWidget {
  const _AiUnavailableBanner();

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: AppColors.warning.withValues(alpha: 0.14),
        borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
        border: Border.all(color: AppColors.warning.withValues(alpha: 0.6)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.cloud_off_rounded, color: AppColors.warning),
          const SizedBox(width: AppSpacing.sm + 4),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('AI sedang bermasalah', style: textTheme.titleSmall),
                const SizedBox(height: 2),
                Text(
                  'Pengeluaran tetap bisa dicatat, tapi tanpa klasifikasi '
                  'otomatis sehingga masuk ke tipe Lain-lain. Isi nominalnya '
                  'dulu ya. Tipe boleh kamu ubah sendiri.',
                  style: textTheme.bodySmall,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _SaveBar extends ConsumerWidget {
  const _SaveBar({required this.state});

  final ExpenseAiState state;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final textTheme = Theme.of(context).textTheme;
    final saving = state.phase == ExpenseAiPhase.saving;

    final hint = state.pendingReviewCount > 0
        ? 'Masih ada ${state.pendingReviewCount} item perlu dicek.'
        : (state.missingAmountCount > 0
              ? 'Isi nominal semua item dulu.'
              : null);

    return Material(
      color: AppColors.surface,
      elevation: 8,
      shadowColor: Colors.black26,
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(
            AppSpacing.lg,
            AppSpacing.md,
            AppSpacing.lg,
            AppSpacing.md,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                children: [
                  Text(
                    'Total pengeluaran',
                    style: textTheme.bodyMedium?.copyWith(
                      color: AppColors.onSurfaceVariant,
                    ),
                  ),
                  const Spacer(),
                  Text(
                    RupiahFormatter.full(state.total),
                    style: textTheme.titleMedium,
                  ),
                ],
              ),
              if (hint != null) ...[
                const SizedBox(height: 4),
                Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    hint,
                    style: textTheme.bodySmall?.copyWith(
                      color: AppColors.error,
                    ),
                  ),
                ),
              ],
              const SizedBox(height: AppSpacing.sm + 4),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: saving ? null : () => _cancel(context, ref),
                      style: OutlinedButton.styleFrom(
                        minimumSize: const Size(0, 48),
                      ),
                      child: const Text('Batal'),
                    ),
                  ),
                  const SizedBox(width: AppSpacing.sm + 4),
                  Expanded(
                    flex: 2,
                    child: FilledButton(
                      onPressed: state.canSave ? () => _save(context, ref) : null,
                      style: FilledButton.styleFrom(
                        minimumSize: const Size(0, 48),
                      ),
                      child: saving
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: AppColors.onPrimary,
                              ),
                            )
                          : const Text('Simpan'),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _save(BuildContext context, WidgetRef ref) async {
    final messenger = ScaffoldMessenger.of(context);
    final router = GoRouter.of(context);

    final count = await ref.read(expenseAiProvider.notifier).confirm();
    if (count != null) {
      messenger
        ..hideCurrentSnackBar()
        ..showSnackBar(SnackBar(content: Text('$count pengeluaran tercatat.')));
      router.go(RoutePaths.ownerFinance);
      return;
    }
    final message = ref.read(expenseAiProvider).errorMessage;
    if (message != null) {
      messenger
        ..hideCurrentSnackBar()
        ..showSnackBar(SnackBar(content: Text(message)));
    }
  }

  Future<void> _cancel(BuildContext context, WidgetRef ref) async {
    final router = GoRouter.of(context);
    final discard = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Buang hasil ini?'),
        content: const Text(
          'Hasil AI tidak akan disimpan. Teks dan nota yang kamu isi tetap ada.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('Lanjut periksa'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            child: const Text('Buang'),
          ),
        ],
      ),
    );
    if (discard != true) return;
    await ref.read(expenseAiProvider.notifier).discardDraft();
    router.pop();
  }
}
