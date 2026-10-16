import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:rijiki/app/router/route_paths.dart';
import 'package:rijiki/core/theme/app_colors.dart';
import 'package:rijiki/core/theme/app_spacing.dart';
import 'package:rijiki/features/finance/presentation/controllers/finance_controller.dart';
import 'package:rijiki/features/finance/presentation/widgets/expense_type_breakdown_chart.dart';
import 'package:rijiki/features/finance/presentation/widgets/export_range_sheet.dart';
import 'package:rijiki/features/finance/presentation/widgets/finance_period_selector.dart';
import 'package:rijiki/features/finance/presentation/widgets/finance_state_card.dart';
import 'package:rijiki/features/finance/presentation/widgets/finance_summary_card.dart';
import 'package:rijiki/features/finance/presentation/widgets/revenue_chart.dart';
import 'package:rijiki/shared/widgets/error_state.dart';
import 'package:rijiki/shared/widgets/loading_skeleton.dart';

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
            onPressed: () => showExportRangeSheet(context),
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
                    const _QuickActions(),
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
              FinanceStateCard(
                child: ErrorState(
                  message: 'Gagal memuat data keuangan.',
                  onRetry: () => ref.invalidate(financeSummaryProvider),
                ),
              ),
              const SizedBox(height: AppSpacing.md),
              const _QuickActions(),
            ] else
              const _FinanceSkeleton(),
          ],
        ),
      ),
    );
  }
}

class _QuickActions extends StatelessWidget {
  const _QuickActions();

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        IntrinsicHeight(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Expanded(
                child: _ActionTile(
                  icon: Icons.add_card_rounded,
                  color: AppColors.rijikiOrange,
                  title: 'Catat pengeluaran',
                  subtitle: 'Ceritakan, AI yang catat',
                  onTap: () => context.push(RoutePaths.ownerFinanceExpenseAi),
                ),
              ),
              const SizedBox(width: AppSpacing.sm + 4),
              Expanded(
                child: _ActionTile(
                  icon: Icons.savings_rounded,
                  color: AppColors.success,
                  title: 'Catat pemasukan',
                  subtitle: 'Di luar order, mis. hibah',
                  onTap: () => context.push(RoutePaths.ownerFinanceIncomeNew),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: AppSpacing.sm + 4),
        _WideActionTile(
          icon: Icons.receipt_long_rounded,
          color: AppColors.rijikiBlue,
          title: 'Rekap transaksi',
          subtitle: 'Semua pemasukan dan pengeluaran',
          onTap: () => context.push(RoutePaths.ownerFinanceTransactions),
        ),
      ],
    );
  }
}

class _IconBadge extends StatelessWidget {
  const _IconBadge({required this.icon, required this.color});

  final IconData icon;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 36,
      height: 36,
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.14),
        borderRadius: BorderRadius.circular(AppSpacing.radiusMd - 2),
      ),
      child: Icon(icon, size: AppSpacing.iconSm + 2, color: color),
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
              _IconBadge(icon: icon, color: color),
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

class _WideActionTile extends StatelessWidget {
  const _WideActionTile({
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
          child: Row(
            children: [
              _IconBadge(icon: icon, color: color),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
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
              const Icon(
                Icons.chevron_right_rounded,
                color: AppColors.onSurfaceVariant,
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
    const radius = AppSpacing.radiusLg;
    return const Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        LoadingSkeleton(height: 210, radius: radius),
        SizedBox(height: AppSpacing.md),
        LoadingSkeleton(height: 170, radius: radius),
        SizedBox(height: AppSpacing.md),
        LoadingSkeleton(height: 290, radius: radius),
        SizedBox(height: AppSpacing.md),
        LoadingSkeleton(height: 380, radius: radius),
      ],
    );
  }
}
