import 'package:flutter/material.dart';
import 'package:rijiki/core/theme/app_colors.dart';
import 'package:rijiki/core/theme/app_spacing.dart';
import 'package:rijiki/features/finance/domain/finance_summary.dart';
import 'package:rijiki/features/finance/presentation/utils/finance_format.dart';
import 'package:rijiki/shared/widgets/animated_rupiah.dart';

class FinanceSummaryCard extends StatelessWidget {
  const FinanceSummaryCard({super.key, required this.summary});

  final FinanceSummary summary;

  static const Color _up = Color(0xFF7FE3A2);
  static const Color _down = Color(0xFFFF8A80);

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final profit = summary.profit;
    final margin = summary.profitMarginPct;
    final change = summary.incomeChangePct;

    return ClipRRect(
      borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
      child: DecoratedBox(
        decoration: const BoxDecoration(color: AppColors.onPrimary),
        child: Stack(
          children: [
            Positioned(
              top: -50,
              right: -40,
              child: Container(
                width: 170,
                height: 170,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: AppColors.rijikiBlue.withValues(alpha: 0.16),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(AppSpacing.md),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(
                        'Laba',
                        style: textTheme.labelLarge?.copyWith(
                          color: Colors.white.withValues(alpha: 0.7),
                        ),
                      ),
                      const Spacer(),
                      if (margin != null)
                        _Pill(
                          text: 'Margin ${margin.toStringAsFixed(0)}%',
                          color: margin >= 0 ? _up : _down,
                        ),
                    ],
                  ),
                  const SizedBox(height: AppSpacing.xs),
                  AnimatedRupiah(
                    value: profit,
                    style: textTheme.headlineMedium?.copyWith(
                      color: profit >= 0 ? Colors.white : _down,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    summary.period.label,
                    style: textTheme.bodySmall?.copyWith(
                      color: Colors.white.withValues(alpha: 0.55),
                    ),
                  ),
                  const SizedBox(height: AppSpacing.md),
                  Divider(
                    height: 1,
                    color: Colors.white.withValues(alpha: 0.12),
                  ),
                  const SizedBox(height: AppSpacing.md),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: _Metric(
                          icon: Icons.north_east_rounded,
                          color: _up,
                          label: 'Pemasukan',
                          value: summary.income,
                          footnote: change == null
                              ? null
                              : '${formatPercentSigned(change)} '
                                    '${summary.period.compareLabel}',
                          footnoteColor: (change ?? 0) >= 0 ? _up : _down,
                        ),
                      ),
                      const SizedBox(width: AppSpacing.md),
                      Expanded(
                        child: _Metric(
                          icon: Icons.south_west_rounded,
                          color: AppColors.rijikiOrange,
                          label: 'Pengeluaran',
                          value: summary.expense,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Metric extends StatelessWidget {
  const _Metric({
    required this.icon,
    required this.color,
    required this.label,
    required this.value,
    this.footnote,
    this.footnoteColor,
  });

  final IconData icon;
  final Color color;
  final String label;
  final double value;
  final String? footnote;
  final Color? footnoteColor;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              width: 28,
              height: 28,
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.18),
                borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
              ),
              child: Icon(icon, size: AppSpacing.iconSm, color: color),
            ),
            const SizedBox(width: AppSpacing.sm),
            Flexible(
              child: Text(
                label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: textTheme.bodySmall?.copyWith(
                  color: Colors.white.withValues(alpha: 0.65),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.sm),
        AnimatedRupiah(
          value: value,
          compact: true,
          style: textTheme.titleLarge?.copyWith(
            color: Colors.white,
            fontWeight: FontWeight.w700,
          ),
        ),
        if (footnote != null) ...[
          const SizedBox(height: 2),
          Text(
            footnote!,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: textTheme.labelSmall?.copyWith(color: footnoteColor),
          ),
        ],
      ],
    );
  }
}

class _Pill extends StatelessWidget {
  const _Pill({required this.text, required this.color});

  final String text;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.16),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        text,
        style: Theme.of(context).textTheme.labelMedium?.copyWith(
          color: color,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}
