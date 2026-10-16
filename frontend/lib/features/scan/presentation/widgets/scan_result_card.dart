import 'package:flutter/material.dart';
import 'package:rijiki/core/theme/app_colors.dart';
import 'package:rijiki/core/theme/app_spacing.dart';
import 'package:rijiki/features/scan/domain/scan_result.dart';
import 'package:rijiki/features/scan/presentation/widgets/confidence_bar.dart';
import 'package:rijiki/shared/widgets/app_card.dart';

class ScanResultCard extends StatelessWidget {
  const ScanResultCard({
    super.key,
    required this.icon,
    required this.title,
    required this.predictions,
  });

  final IconData icon;
  final String title;
  final List<ScanPrediction> predictions;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.25),
                  borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
                ),
                child: Icon(icon, size: 18, color: AppColors.primaryDark),
              ),
              const SizedBox(width: 10),
              Text(
                title,
                style: textTheme.labelLarge?.copyWith(
                  color: AppColors.onSurfaceVariant,
                ),
              ),
            ],
          ),
          for (final prediction in predictions) ...[
            const SizedBox(height: 12),
            Text(prediction.label, style: textTheme.titleMedium),
            const SizedBox(height: 6),
            ConfidenceBar(value: prediction.confidence),
          ],
        ],
      ),
    );
  }
}
