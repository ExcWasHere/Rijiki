import 'package:flutter/material.dart';
import 'package:rijiki/core/theme/app_colors.dart';
import 'package:rijiki/core/theme/app_spacing.dart';
import 'package:rijiki/features/worker_management/domain/kpi.dart';
import 'package:rijiki/features/worker_management/presentation/utils/worker_format.dart';

class KpiPeriodPicker extends StatelessWidget {
  const KpiPeriodPicker({
    super.key,
    required this.period,
    required this.onPrevious,
    required this.onNext,
  });

  final KpiPeriod period;
  final VoidCallback onPrevious;
  final VoidCallback onNext;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 4),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
        border: Border.all(color: AppColors.outline.withValues(alpha: 0.3)),
      ),
      child: Row(
        children: [
          IconButton(
            tooltip: 'Bulan sebelumnya',
            onPressed: onPrevious,
            icon: const Icon(Icons.chevron_left_rounded),
          ),
          Expanded(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  formatPeriod(period),
                  style: textTheme.titleSmall,
                ),
                if (period.isCurrent)
                  Text(
                    'Bulan berjalan',
                    style: textTheme.labelSmall?.copyWith(
                      color: AppColors.primaryDark,
                    ),
                  ),
              ],
            ),
          ),
          IconButton(
            tooltip: 'Bulan berikutnya',
            onPressed: period.isCurrent ? null : onNext,
            icon: const Icon(Icons.chevron_right_rounded),
          ),
        ],
      ),
    );
  }
}
