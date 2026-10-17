import 'package:flutter/material.dart';
import 'package:rijiki/core/enums/app_permission.dart';
import 'package:rijiki/core/theme/app_colors.dart';
import 'package:rijiki/core/theme/app_spacing.dart';
import 'package:rijiki/features/access_control/presentation/utils/permission_ui.dart';

class PermissionToggleTile extends StatelessWidget {
  const PermissionToggleTile({
    super.key,
    required this.permission,
    required this.value,
    required this.onChanged,
  });

  final AppPermission permission;
  final bool value;
  final ValueChanged<bool>? onChanged;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return Padding(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.md,
        AppSpacing.sm + 2,
        AppSpacing.sm,
        AppSpacing.sm + 2,
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(permission.label, style: textTheme.titleSmall),
                const SizedBox(height: 2),
                Text(
                  permission.description,
                  style: textTheme.bodySmall?.copyWith(
                    color: AppColors.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
          Switch(value: value, onChanged: onChanged),
        ],
      ),
    );
  }
}
