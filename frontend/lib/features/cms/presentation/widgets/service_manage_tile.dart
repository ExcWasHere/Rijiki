import 'package:flutter/material.dart';
import 'package:rijiki/core/theme/app_colors.dart';
import 'package:rijiki/core/theme/app_spacing.dart';
import 'package:rijiki/core/utils/rupiah_formatter.dart';
import 'package:rijiki/features/cms/presentation/utils/service_format.dart';
import 'package:rijiki/features/service/domain/care_service.dart';

class ServiceManageTile extends StatelessWidget {
  const ServiceManageTile({
    super.key,
    required this.service,
    required this.isActive,
    required this.busy,
    required this.onTap,
    required this.onToggle,
  });

  final CareService service;
  final bool isActive;
  final bool busy;
  final VoidCallback onTap;
  final ValueChanged<bool> onToggle;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final duration = service.estimatedDurationMinutes;
    final dim = !isActive;

    return InkWell(
      onTap: onTap,
      child: Opacity(
        opacity: dim ? 0.6 : 1,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(
            AppSpacing.md,
            AppSpacing.sm + 4,
            AppSpacing.sm,
            AppSpacing.sm + 4,
          ),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      service.name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: textTheme.titleSmall,
                    ),
                    const SizedBox(height: 2),
                    Text(
                      RupiahFormatter.full(service.basePrice.toDouble()),
                      style: textTheme.titleSmall?.copyWith(
                        color: AppColors.primaryDark,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    if (duration != null || service.description != null) ...[
                      const SizedBox(height: 2),
                      Text(
                        [
                          if (duration != null)
                            'Estimasi ${formatDuration(duration)}',
                          if (service.description != null) service.description!,
                        ].join(' · '),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: textTheme.bodySmall?.copyWith(
                          color: AppColors.onSurfaceVariant,
                        ),
                      ),
                    ],
                    if (!isActive) ...[
                      const SizedBox(height: 6),
                      const _InactiveChip(),
                    ],
                  ],
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              busy
                  ? const Padding(
                      padding: EdgeInsets.symmetric(horizontal: 14),
                      child: SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      ),
                    )
                  : Switch(value: isActive, onChanged: onToggle),
            ],
          ),
        ),
      ),
    );
  }
}

class _InactiveChip extends StatelessWidget {
  const _InactiveChip();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: AppColors.outline.withValues(alpha: 0.2),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        'Nonaktif · tidak tampil di customer',
        style: Theme.of(context).textTheme.labelSmall?.copyWith(
          color: AppColors.onSurfaceVariant,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}
