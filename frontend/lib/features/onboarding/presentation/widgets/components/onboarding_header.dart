import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:rijiki/core/theme/app_colors.dart';
import 'package:rijiki/features/onboarding/presentation/controllers/onboarding_controller.dart';

class OnboardingHeader extends ConsumerWidget {
  final int currentPage;

  const OnboardingHeader({
    super.key,
    required this.currentPage,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (currentPage == 2) {
      final userName = ref.watch(onboardingControllerProvider).name;
      final displayName = userName.trim().isNotEmpty ? userName.trim() : 'user';

      return Align(
        alignment: Alignment.centerLeft,
        child: Text(
          'Halo, $displayName',
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: AppColors.onSurface,
          ),
        ),
      );
    }

    return Center(
      child: RichText(
        text: const TextSpan(
          children: [
            TextSpan(
              text: 'Rijiki ',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: AppColors.onSurface,
              ),
            ),
            TextSpan(
              text: 'x ',
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w600,
                color: AppColors.rijikiOrange,
              ),
            ),
            TextSpan(
              text: 'TaTuTi',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: AppColors.onSurface,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
