import 'package:flutter/material.dart';
import 'package:rijiki/core/theme/app_colors.dart';
import 'package:rijiki/features/onboarding/presentation/controllers/onboarding_controller.dart';

class OnboardingBottomNav extends StatelessWidget {
  final int currentPage;
  final VoidCallback? onBack;
  final VoidCallback? onNext;
  final bool isLoading;

  const OnboardingBottomNav({
    super.key,
    required this.currentPage,
    this.onBack,
    this.onNext,
    this.isLoading = false,
  });

  Widget _spinner() {
    return const SizedBox(
      width: 18,
      height: 18,
      child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isFirstPage = currentPage == 0;
    final isLastPage = currentPage == OnboardingController.lastPage;

    if (isFirstPage) {
      return SizedBox(
        width: double.infinity,
        height: 48,
        child: ElevatedButton(
          onPressed: isLoading ? null : onNext,
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.rijikiBlue,
            foregroundColor: Colors.white,
            elevation: 0,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
          ),
          child: const Text(
            'NEXT',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              letterSpacing: 1.1,
            ),
          ),
        ),
      );
    }

    return Row(
      children: [
        Expanded(
          child: SizedBox(
            height: 44,
            child: OutlinedButton(
              onPressed: isLoading ? null : onBack,
              style: OutlinedButton.styleFrom(
                foregroundColor: Colors.grey.shade700,
                side: BorderSide(color: Colors.grey.shade300),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              child: const Text(
                'BACK',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 1.0,
                ),
              ),
            ),
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: SizedBox(
            height: 44,
            child: ElevatedButton(
              onPressed: isLoading ? null : onNext,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.rijikiBlue,
                foregroundColor: Colors.white,
                disabledBackgroundColor: AppColors.rijikiBlue.withValues(
                  alpha: 0.7,
                ),
                disabledForegroundColor: Colors.white,
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              child: isLoading
                  ? _spinner()
                  : Text(
                      isLastPage ? 'SELESAI' : 'NEXT',
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 1.0,
                      ),
                    ),
            ),
          ),
        ),
      ],
    );
  }
}
