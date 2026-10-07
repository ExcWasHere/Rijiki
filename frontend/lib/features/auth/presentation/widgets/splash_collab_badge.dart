import 'package:flutter/material.dart';
import '/../core/constants/app_strings.dart';
import '/../core/theme/app_colors.dart';

class SplashCollabBadge extends StatelessWidget {
  const SplashCollabBadge({super.key});

  @override
  Widget build(BuildContext context) {
    const textStyle = TextStyle(
      fontSize: 10,
      fontWeight: FontWeight.w600,
      height: 1,
      color: AppColors.onPrimary,
    );

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(AppStrings.collabPrimary, style: textStyle),
        Text('×', style: textStyle.copyWith(color: AppColors.onSurfaceVariant)),
        Text(AppStrings.collabSecondary, style: textStyle),
      ],
    );
  }
}