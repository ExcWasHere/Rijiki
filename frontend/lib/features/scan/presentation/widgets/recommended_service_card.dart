import 'package:flutter/material.dart';
import 'package:rijiki/core/theme/app_colors.dart';
import 'package:rijiki/core/theme/app_spacing.dart';
import 'package:rijiki/core/utils/currency_formatter.dart';
import 'package:rijiki/features/service/domain/care_service.dart';
import 'package:rijiki/shared/widgets/status_chip.dart';

class RecommendedServiceCard extends StatelessWidget {
  const RecommendedServiceCard({
    super.key,
    required this.service,
    required this.reason,
  });

  final CareService service;
  final String reason;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: const Color(0xFFE6F6FD),
        borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
        border: Border.all(color: AppColors.primary),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const StatusChip(
            label: 'Rekomendasi',
            color: AppColors.primaryDark,
            icon: Icons.auto_awesome_rounded,
          ),
          const SizedBox(height: 10),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(child: Text(service.name, style: textTheme.titleLarge)),
              Text(
                CurrencyFormatter.rupiah(service.basePrice),
                style: textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(reason, style: textTheme.bodyMedium),
        ],
      ),
    );
  }
}
