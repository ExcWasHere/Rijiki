import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:rijiki/core/theme/app_colors.dart';
import 'package:rijiki/core/theme/app_spacing.dart';
import 'package:rijiki/features/home/presentation/owner/domain/dashboard_summary.dart';

class PeriodSelector extends StatelessWidget {
  const PeriodSelector({
    super.key,
    required this.selected,
    required this.onChanged,
  });

  final DashboardPeriod selected;
  final ValueChanged<DashboardPeriod> onChanged;

  static const double _height = 44;
  static const double _padding = 4;

  @override
  Widget build(BuildContext context) {
    const periods = DashboardPeriod.values;
    final textTheme = Theme.of(context).textTheme;

    return Container(
      height: _height,
      padding: const EdgeInsets.all(_padding),
      decoration: BoxDecoration(
        color: AppColors.outline.withValues(alpha: 0.14),
        borderRadius: BorderRadius.circular(AppSpacing.radiusMd + 2),
      ),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final segmentWidth = constraints.maxWidth / periods.length;

          return Stack(
            children: [
              AnimatedPositioned(
                duration: const Duration(milliseconds: 300),
                curve: Curves.easeOutCubic,
                left: selected.index * segmentWidth,
                top: 0,
                bottom: 0,
                width: segmentWidth,
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    color: AppColors.surface,
                    borderRadius: BorderRadius.circular(AppSpacing.radiusMd - 2),
                    boxShadow: AppSpacing.shadowSm,
                  ),
                ),
              ),
              Row(
                children: [
                  for (final period in periods)
                    Expanded(
                      child: GestureDetector(
                        behavior: HitTestBehavior.opaque,
                        onTap: () {
                          if (period == selected) return;
                          HapticFeedback.selectionClick();
                          onChanged(period);
                        },
                        child: Center(
                          child: AnimatedDefaultTextStyle(
                            duration: const Duration(milliseconds: 200),
                            style: textTheme.labelLarge!.copyWith(
                              color: period == selected
                                  ? AppColors.onSurface
                                  : AppColors.onSurfaceVariant,
                              fontWeight: period == selected
                                  ? FontWeight.w700
                                  : FontWeight.w500,
                            ),
                            child: Text(period.label),
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ],
          );
        },
      ),
    );
  }
}
