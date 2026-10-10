import 'package:flutter/material.dart';
import 'package:rijiki/core/theme/app_colors.dart';
import 'package:rijiki/core/theme/app_spacing.dart';
import 'package:rijiki/features/home/presentation/owner/domain/dashboard_summary.dart';
import 'package:rijiki/features/home/presentation/owner/presentation/widgets/animated_rupiah.dart';

class SummaryStatRow extends StatelessWidget {
  const SummaryStatRow({
    super.key,
    required this.summary,
    this.onActiveOrdersTap,
  });

  final DashboardSummary summary;
  final VoidCallback? onActiveOrdersTap;

  @override
  Widget build(BuildContext context) {
    final profit = summary.profit;
    final profitColor = profit >= 0 ? AppColors.success : AppColors.error;

    return Column(
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Expanded(
              child: _StatTile(
                icon: Icons.south_west_rounded,
                color: AppColors.rijikiOrange,
                label: 'Pengeluaran',
                value: AnimatedRupiah(
                  value: summary.expense,
                  compact: true,
                  style: _valueStyle(context),
                ),
              ),
            ),
            const SizedBox(width: AppSpacing.sm + 4),
            Expanded(
              child: _StatTile(
                icon: Icons.account_balance_wallet_outlined,
                color: profitColor,
                label: 'Laba',
                value: AnimatedRupiah(
                  value: profit,
                  compact: true,
                  style: _valueStyle(context).copyWith(color: profitColor),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.sm + 4),
        _ActiveOrdersTile(
          count: summary.activeOrders,
          onTap: onActiveOrdersTap,
        ),
      ],
    );
  }

  TextStyle _valueStyle(BuildContext context) =>
      Theme.of(context).textTheme.titleLarge!.copyWith(
        fontWeight: FontWeight.w700,
        color: AppColors.onSurface,
      );
}

class _StatTile extends StatelessWidget {
  const _StatTile({
    required this.icon,
    required this.color,
    required this.label,
    required this.value,
  });

  final IconData icon;
  final Color color;
  final String label;
  final Widget value;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
        border: Border.all(color: AppColors.outline.withValues(alpha: 0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _IconBadge(icon: icon, color: color),
          const SizedBox(height: AppSpacing.md),
          Text(
            label,
            style: textTheme.bodySmall?.copyWith(
              color: AppColors.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 2),
          value,
        ],
      ),
    );
  }
}

class _ActiveOrdersTile extends StatelessWidget {
  const _ActiveOrdersTile({required this.count, this.onTap});

  final int count;
  final VoidCallback? onTap;

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
              const _IconBadge(
                icon: Icons.local_laundry_service_outlined,
                color: AppColors.rijikiBlue,
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Order aktif',
                      style: textTheme.bodySmall?.copyWith(
                        color: AppColors.onSurfaceVariant,
                      ),
                    ),
                    Text(
                      '$count order sedang diproses',
                      style: textTheme.titleMedium,
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
