import 'package:flutter/material.dart';
import 'package:rijiki/core/theme/app_colors.dart';

class OnboardingDots extends StatelessWidget {
  final int currentPage;
  final int totalDots;

  const OnboardingDots({
    super.key,
    required this.currentPage,
    this.totalDots = 3,
  });

  @override
  Widget build(BuildContext context) {
    // Map 5 pages to dot active position if totalDots is 3 or 5
    // Screen 0 -> Dot 0
    // Screen 1 -> Dot 1
    // Screen 2 (Questionnaire) -> Can hide or show Dot 1
    // Screen 3 -> Dot 1
    // Screen 4 -> Dot 2
    int activeIndex = currentPage;
    if (totalDots == 3) {
      if (currentPage <= 0) {
        activeIndex = 0;
      } else if (currentPage >= 6) {
        activeIndex = 2;
      } else {
        activeIndex = 1;
      }
    }

    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(totalDots, (index) {
        final isActive = index == activeIndex;
        return AnimatedContainer(
          duration: const Duration(milliseconds: 250),
          margin: const EdgeInsets.symmetric(horizontal: 4.0),
          width: isActive ? 10.0 : 8.0,
          height: isActive ? 10.0 : 8.0,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: isActive ? AppColors.rijikiBlue : AppColors.outline.withValues(alpha: 0.4),
          ),
        );
      }),
    );
  }
}
