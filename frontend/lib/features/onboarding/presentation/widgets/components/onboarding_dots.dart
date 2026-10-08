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
