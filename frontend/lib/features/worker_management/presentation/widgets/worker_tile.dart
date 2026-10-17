import 'package:flutter/material.dart';
import 'package:rijiki/core/theme/app_colors.dart';
import 'package:rijiki/core/theme/app_spacing.dart';
import 'package:rijiki/features/worker_management/domain/worker_profile.dart';
import 'package:rijiki/features/worker_management/presentation/utils/worker_format.dart';
import 'package:rijiki/features/worker_management/presentation/widgets/worker_avatar.dart';

class WorkerTile extends StatelessWidget {
  const WorkerTile({super.key, required this.summary, required this.onTap});

  final WorkerSummary summary;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final worker = summary.profile;

    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.md,
          vertical: AppSpacing.sm + 4,
        ),
        child: Row(
          children: [
            WorkerAvatar(name: worker.fullName, avatarUrl: worker.avatarUrl),
            const SizedBox(width: AppSpacing.md),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    worker.fullName,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: textTheme.titleSmall,
                  ),
                  const SizedBox(height: 2),
                  Text(
                    '${worker.employeeCode} · ${worker.division}',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: textTheme.bodySmall?.copyWith(
                      color: AppColors.onSurfaceVariant,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      const Icon(
                        Icons.star_rounded,
                        size: 15,
                        color: Color(0xFFFFB800),
                      ),
                      const SizedBox(width: 3),
                      Text(
                        summary.avgRating == null
                            ? 'Belum ada rating'
                            : '${formatRating(summary.avgRating)} '
                                  '(${summary.ratingCount})',
                        style: textTheme.labelMedium?.copyWith(
                          color: AppColors.onSurface,
                        ),
                      ),
                    ],
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
    );
  }
}
