import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:rijiki/app/router/route_paths.dart';
import 'package:rijiki/core/theme/app_colors.dart';
import 'package:rijiki/core/theme/app_spacing.dart';
import 'package:rijiki/features/finance/presentation/controllers/finance_controller.dart';
import 'package:rijiki/features/finance/presentation/widgets/expense_type_breakdown_chart.dart';
import 'package:rijiki/features/finance/presentation/widgets/finance_period_selector.dart';
import 'package:rijiki/features/finance/presentation/widgets/finance_summary_card.dart';
import 'package:rijiki/features/finance/presentation/widgets/revenue_chart.dart';
import 'package:rijiki/features/home/owner/presentation/widgets/dashboard_message_card.dart';
import 'package:rijiki/features/home/owner/presentation/widgets/skeleton_block.dart';

class FinancePage extends ConsumerWidget {
  const FinancePage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final period = ref.watch(financePeriodProvider);
    final async = ref.watch(financeSummaryProvider);
    final summary = async.value;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Keuangan'),
        actions: [
          IconButton(
            tooltip: 'Export Excel',
            icon: const Icon(Icons.file_download_outlined),
            onPressed: () => _comingSoon(context, 'Export Excel'),
          ),
        ],
      ),
      body: RefreshIndicator(
        color: AppColors.primaryDark,
        onRefresh: () => refreshFinance(ref),
        child: ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.fromLTRB(
            AppSpacing.lg,
            AppSpacing.md,
            AppSpacing.lg,
            AppSpacing.xl,
          ),
          children: [
            FinancePeriodSelector(
              selected: period,
              onChanged: (value) =>
                  ref.read(financePeriodProvider.notifier).select(value),
            ),
            const SizedBox(height: AppSpacing.md),
            if (summary != null)
              AnimatedOpacity(
                duration: const Duration(milliseconds: 200),
                opacity: async.isLoading ? 0.55 : 1,
                child: Column(
                  children: [
                    FinanceSummaryCard(summary: summary),
                    const SizedBox(height: AppSpacing.md),
                    _QuickActions(
                      onAddExpense: () =>
                          _comingSoon(context, 'Catat pengeluaran'),
                      onTransactions: () =>
                          context.push(RoutePaths.ownerFinanceTransactions),
                    ),
                    const SizedBox(height: AppSpacing.md),
                    RevenueChart(
                      key: ValueKey(summary.period),
                      summary: summary,
                    ),
                    const SizedBox(height: AppSpacing.md),
                    ExpenseTypeBreakdownChart(
                      key: ValueKey('breakdown-${summary.period.name}'),
                      summary: summary,
                    ),
                  ],
                ),
              )
            else if (async.hasError) ...[
              DashboardMessageCard(
                icon: Icons.cloud_off_rounded,
                message: 'Gagal memuat data keuangan.',
                actionLabel: 'Coba lagi',
                onAction: () => ref.invalidate(financeSummaryProvider),
              ),
              const SizedBox(height: AppSpacing.md),
              _QuickActions(
                onAddExpense: () => _comingSoon(context, 'Catat pengeluaran'),
                onTransactions: () =>
                    context.push(RoutePaths.ownerFinanceTransactions),
              ),
            ] else
              const _FinanceSkeleton(),
          ],
        ),
      ),
    );
  }

  static void _comingSoon(BuildContext context, String feature) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text('$feature segera hadir.')));
  }
}

class _QuickActions extends StatelessWidget {
  const _QuickActions({
    required this.onAddExpense,
    required this.onTransactions,
  });

  final VoidCallback onAddExpense;
  final VoidCallback onTransactions;

  @override
  Widget build(BuildContext context) {
    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Expanded(
            child: _ActionTile(
              icon: Icons.add_card_rounded,
              color: AppColors.rijikiOrange,
              title: 'Catat pengeluaran',
              subtitle: 'Input AI atau manual',
              onTap: onAddExpense,
            ),
          ),
          const SizedBox(width: AppSpacing.sm + 4),
          Expanded(
            child: _ActionTile(
              icon: Icons.receipt_long_rounded,
              color: AppColors.rijikiBlue,
              title: 'Rekap transaksi',
              subtitle: 'Pemasukan dan pengeluaran',
              onTap: onTransactions,
            ),
          ),
        ],
      ),
    );
  }
}

class _ActionTile extends StatelessWidget {
  const _ActionTile({
    required this.icon,
    required this.color,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  final IconData icon;
  final Color color;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return Material(
      color: AppColors.surface,
      borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
      child: InkWell(
        borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
        onTap: onTap,
        child: Ink(
          padding: const EdgeInsets.all(AppSpacing.md),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
            border: Border.all(color: AppColors.outline.withValues(alpha: 0.3)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.14),
                  borderRadius: BorderRadius.circular(AppSpacing.radiusMd - 2),
                ),
                child: Icon(icon, size: AppSpacing.iconSm + 2, color: color),
              ),
              const SizedBox(height: AppSpacing.sm + 4),
              Text(title, style: textTheme.titleSmall),
              const SizedBox(height: 2),
              Text(
                subtitle,
                style: textTheme.bodySmall?.copyWith(
                  color: AppColors.onSurfaceVariant,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _FinanceSkeleton extends StatelessWidget {
  const _FinanceSkeleton();

  @override
  Widget build(BuildContext context) {
    return const Column(
      children: [
        SkeletonBlock(height: 210),
        SizedBox(height: AppSpacing.md),
        SkeletonBlock(height: 110),
        SizedBox(height: AppSpacing.md),
        SkeletonBlock(height: 290),
        SizedBox(height: AppSpacing.md),
        SkeletonBlock(height: 380),
      ],
    );
  }
}
