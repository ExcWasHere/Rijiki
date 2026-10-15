import 'package:flutter/material.dart';
import 'package:rijiki/core/theme/app_colors.dart';
import 'package:rijiki/core/theme/app_spacing.dart';

class CmsItemTile extends StatelessWidget {
  const CmsItemTile({
    super.key,
    required this.leading,
    required this.title,
    required this.isActive,
    required this.busy,
    required this.inactiveLabel,
    required this.onTap,
    required this.onToggle,
    this.details = const [],
  });

  final Widget leading;
  final String title;
  final List<Widget> details;
  final bool isActive;
  final bool busy;
  final String inactiveLabel;
  final VoidCallback onTap;
  final ValueChanged<bool> onToggle;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return InkWell(
      onTap: onTap,
      child: Opacity(
        opacity: isActive ? 1 : 0.6,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(
            AppSpacing.md,
            AppSpacing.sm + 4,
            AppSpacing.sm,
            AppSpacing.sm + 4,
          ),
          child: Row(
            children: [
              leading,
              const SizedBox(width: AppSpacing.sm + 4),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: textTheme.titleSmall,
                    ),
                    for (final detail in details) ...[
                      const SizedBox(height: 4),
                      detail,
                    ],
                    if (!isActive) ...[
                      const SizedBox(height: 6),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 3,
                        ),
                        decoration: BoxDecoration(
                          color: AppColors.outline.withValues(alpha: 0.2),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          inactiveLabel,
                          style: textTheme.labelSmall?.copyWith(
                            color: AppColors.onSurfaceVariant,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
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
