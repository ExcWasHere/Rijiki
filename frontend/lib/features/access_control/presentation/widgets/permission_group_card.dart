import 'package:flutter/material.dart';
import 'package:rijiki/core/enums/app_permission.dart';
import 'package:rijiki/core/theme/app_colors.dart';
import 'package:rijiki/core/theme/app_spacing.dart';
import 'package:rijiki/features/access_control/presentation/utils/permission_ui.dart';
import 'package:rijiki/features/access_control/presentation/widgets/permission_toggle_tile.dart';

class PermissionGroupCard extends StatelessWidget {
  const PermissionGroupCard({
    super.key,
    required this.group,
    required this.granted,
    required this.onChanged,
  });

  final PermissionGroup group;
  final Set<AppPermission> granted;
  final void Function(AppPermission permission, bool value)? onChanged;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final activeCount = group.permissions.where(granted.contains).length;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(
            left: AppSpacing.xs,
            bottom: AppSpacing.sm,
          ),
          child: Row(
            children: [
              Icon(group.icon, size: AppSpacing.iconSm, color: AppColors.primaryDark),
              const SizedBox(width: 6),
              Text(
                group.title,
                style: textTheme.labelLarge?.copyWith(
                  color: AppColors.onSurfaceVariant,
                ),
              ),
              if (activeCount > 0) ...[
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 1),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withValues(alpha: 0.3),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    '$activeCount aktif',
                    style: textTheme.labelSmall?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
        Container(
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
            border: Border.all(color: AppColors.outline.withValues(alpha: 0.3)),
          ),
          child: Column(
            children: [
              for (var i = 0; i < group.permissions.length; i++) ...[
                if (i > 0)
                  Divider(
                    height: 1,
                    indent: AppSpacing.md,
                    endIndent: AppSpacing.md,
                    color: AppColors.outline.withValues(alpha: 0.2),
                  ),
                PermissionToggleTile(
                  permission: group.permissions[i],
                  value: granted.contains(group.permissions[i]),
                  onChanged: onChanged == null
                      ? null
                      : (value) => onChanged!(group.permissions[i], value),
                ),
              ],
            ],
          ),
        ),
      ],
    );
  }
}
