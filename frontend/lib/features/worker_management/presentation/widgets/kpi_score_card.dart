import 'package:flutter/material.dart';
import 'package:rijiki/core/theme/app_colors.dart';
import 'package:rijiki/core/theme/app_spacing.dart';
import 'package:rijiki/features/worker_management/domain/kpi.dart';
import 'package:rijiki/features/worker_management/presentation/utils/worker_format.dart';

Color scoreColor(double score) => switch (ScoreBand.of(score)) {
  ScoreBand.excellent => AppColors.success,
  ScoreBand.good => AppColors.primaryDark,
  ScoreBand.fair => AppColors.warning,
  ScoreBand.poor => AppColors.error,
};

class KpiScoreCard extends StatelessWidget {
  const KpiScoreCard({super.key, required this.kpi});

  final WorkerKpi kpi;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final composite = kpi.compositeScore;
    final color = composite == null
        ? AppColors.onSurfaceVariant
        : scoreColor(composite);

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
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                formatScore(composite),
                style: textTheme.displaySmall?.copyWith(
                  color: color,
                  fontWeight: FontWeight.w800,
                  height: 1,
                ),
              ),
              const SizedBox(width: 6),
              Padding(
                padding: const EdgeInsets.only(bottom: 4),
                child: Text(
                  '/ 100',
                  style: textTheme.bodyMedium?.copyWith(
                    color: AppColors.onSurfaceVariant,
                  ),
                ),
              ),
              const Spacer(),
              _BandChip(composite: composite, color: color),
            ],
          ),
          const SizedBox(height: AppSpacing.sm),
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: LinearProgressIndicator(
              value: composite == null ? 0 : composite / 100,
              minHeight: 8,
              color: color,
              backgroundColor: AppColors.outline.withValues(alpha: 0.18),
            ),
          ),
          const SizedBox(height: 6),
          Text(
            composite == null
                ? 'Skor gabungan muncul setelah Owner memberi penilaian.'
                : 'Skor gabungan: 60% penilaian Owner + 40% rating customer.',
            style: textTheme.bodySmall?.copyWith(
              color: AppColors.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          Row(
            children: [
              Expanded(
                child: _Metric(
                  label: 'Order selesai',
                  value: '${kpi.totalOrdersHandled}',
                ),
              ),
              Expanded(
                child: _Metric(
                  label: 'Tepat waktu',
                  value: kpi.onTimeCompletionPct == null
                      ? '-'
                      : '${kpi.onTimeCompletionPct!.toStringAsFixed(0)}%',
                ),
              ),
              Expanded(
                child: _Metric(
                  label: 'Rating',
                  value: formatRating(kpi.avgRating),
                ),
              ),
              Expanded(
                child: _Metric(
                  label: 'Penilaian',
                  value: formatScore(kpi.operationalScore),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _BandChip extends StatelessWidget {
  const _BandChip({required this.composite, required this.color});

  final double? composite;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final text = composite == null
        ? 'Belum dinilai'
        : ScoreBand.of(composite!).label;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.14),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        text,
        style: Theme.of(context).textTheme.labelMedium?.copyWith(
          color: composite == null ? AppColors.onSurfaceVariant : AppColors.onSurface,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}

class _Metric extends StatelessWidget {
  const _Metric({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(value, style: textTheme.titleMedium),
        Text(
          label,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: textTheme.labelSmall?.copyWith(
            color: AppColors.onSurfaceVariant,
          ),
        ),
      ],
    );
  }
}
