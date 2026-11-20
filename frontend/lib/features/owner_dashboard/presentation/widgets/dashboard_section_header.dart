import 'package:flutter/material.dart';
import 'package:rijiki/core/theme/app_colors.dart';

class DashboardSectionHeader extends StatelessWidget {
  const DashboardSectionHeader({
    super.key,
    required this.title,
    this.actionLabel,
    this.onAction,
  });

  final String title;
  final String? actionLabel;
  final VoidCallback? onAction;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return Row(
      children: [
        Expanded(child: Text(title, style: textTheme.titleMedium)),
        if (actionLabel != null)
          GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTap: onAction,
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 4),
              child: Text(
                actionLabel!,
                style: textTheme.labelLarge?.copyWith(
                  color: AppColors.primaryDark,
                ),
              ),
            ),
          ),
      ],
    );
  }
}
