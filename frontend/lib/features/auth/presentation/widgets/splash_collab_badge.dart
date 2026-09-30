import 'package:flutter/material.dart';
import '/../core/constants/app_strings.dart';
import '/../core/theme/app_colors.dart';

/// Badge kolaborasi 3 baris kecil: "Rijiki" / "x" / "TaTuTI".
/// Muncul fade-in setelah animasi utama ([SplashContent]) selesai.
class SplashCollabBadge extends StatelessWidget {
  const SplashCollabBadge({super.key});

  @override
  Widget build(BuildContext context) {
    const textStyle = TextStyle(
      fontSize: 10,
      fontWeight: FontWeight.w600,
      height: 1,
      color: AppColors.onPrimary, // navy
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