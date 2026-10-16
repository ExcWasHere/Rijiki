import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:rijiki/core/enums/expense_type.dart';
import 'package:rijiki/core/theme/app_colors.dart';
import 'package:rijiki/core/theme/app_spacing.dart';
import 'package:rijiki/features/finance/domain/finance_summary.dart';
import 'package:rijiki/features/finance/presentation/expense_type_ui.dart';
import 'package:rijiki/core/utils/rupiah_formatter.dart';

class ExpenseTypeBreakdownChart extends StatelessWidget {
  const ExpenseTypeBreakdownChart({super.key, required this.summary});

  final FinanceSummary summary;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final total = summary.expense;

    final entries = summary.expenseByType.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

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
            children: [
              Text('Pengeluaran per tipe', style: textTheme.titleMedium),
              const Spacer(),
              Text(
                summary.period.label,
                style: textTheme.bodySmall?.copyWith(
                  color: AppColors.onSurfaceVariant,
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          if (total <= 0)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: AppSpacing.lg),
              child: Center(
                child: Text(
                  'Belum ada pengeluaran di periode ini.',
                  style: textTheme.bodyMedium?.copyWith(
                    color: AppColors.onSurfaceVariant,
                  ),
                ),
              ),
            )
          else ...[
            Center(
              child: SizedBox(
                width: 160,
                height: 160,
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    PieChart(
                      PieChartData(
                        startDegreeOffset: -90,
                        sectionsSpace: 3,
                        centerSpaceRadius: 54,
                        pieTouchData: PieTouchData(enabled: false),
                        sections: [
                          for (final entry in entries)
                            if (entry.value > 0)
                              PieChartSectionData(
                                value: entry.value,
                                color: entry.key.color,
                                radius: 22,
                                showTitle: false,
                              ),
                        ],
                      ),
                    ),
                    Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          'Total',
                          style: textTheme.bodySmall?.copyWith(
                            color: AppColors.onSurfaceVariant,
                          ),
                        ),
                        Text(
                          RupiahFormatter.compact(total),
                          style: textTheme.titleMedium,
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: AppSpacing.md),
            for (var i = 0; i < entries.length; i++) ...[
              if (i > 0) const SizedBox(height: AppSpacing.sm + 4),
              _LegendRow(
                type: entries[i].key,
                amount: entries[i].value,
                percent: entries[i].value / total * 100,
              ),
            ],
          ],
        ],
      ),
    );
  }
}

class _LegendRow extends StatelessWidget {
  const _LegendRow({
    required this.type,
    required this.amount,
    required this.percent,
  });

  final ExpenseType type;
  final double amount;
  final double percent;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return Row(
      children: [
        Container(
          width: 32,
          height: 32,
          decoration: BoxDecoration(
            color: type.color.withValues(alpha: 0.14),
            borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
          ),
          child: Icon(type.icon, size: AppSpacing.iconSm, color: type.color),
        ),
        const SizedBox(width: AppSpacing.sm + 4),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(type.label, style: textTheme.titleSmall),
              Text(
                '${percent.toStringAsFixed(0)}% dari pengeluaran',
                style: textTheme.bodySmall?.copyWith(
                  color: AppColors.onSurfaceVariant,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(width: AppSpacing.sm),
        Text(RupiahFormatter.full(amount), style: textTheme.titleSmall),
      ],
    );
  }
}
