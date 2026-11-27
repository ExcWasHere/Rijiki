import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:rijiki/app/router/route_paths.dart';
import 'package:rijiki/core/error/failure_presenter.dart';
import 'package:rijiki/core/theme/app_spacing.dart';
import 'package:rijiki/features/onboarding/presentation/controllers/onboarding_controller.dart';
import 'package:rijiki/features/onboarding/presentation/widgets/components/onboarding_bottom_nav.dart';
import 'package:rijiki/features/onboarding/presentation/widgets/components/onboarding_dots.dart';
import 'package:rijiki/features/onboarding/presentation/widgets/steps/step_address.dart';
import 'package:rijiki/features/onboarding/presentation/widgets/steps/step_name.dart';
import 'package:rijiki/features/onboarding/presentation/widgets/steps/step_phone.dart';

class OnboardingPage extends ConsumerWidget {
  const OnboardingPage({super.key});

  void _showMessage(BuildContext context, String message) {
    FocusManager.instance.primaryFocus?.unfocus();
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(message)));
  }

  void _next(BuildContext context, OnboardingController controller) {
    final error = controller.validateCurrentPage();
    if (error != null) {
      _showMessage(context, error);
      return;
    }
    controller.nextPage();
  }

  Future<void> _submit(
    BuildContext context,
    OnboardingController controller,
  ) async {
    final error = controller.validateCurrentPage();
    if (error != null) {
      _showMessage(context, error);
      return;
    }

    try {
      await controller.complete();
      if (context.mounted) context.go(RoutePaths.customerHome);
    } catch (e) {
      if (!context.mounted) return;
      final String? message = FailurePresenter.describe(e).message;
      _showMessage(context, message ?? 'Gagal menyimpan data. Coba lagi.');
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(onboardingControllerProvider);
    final controller = ref.read(onboardingControllerProvider.notifier);
    final keyboardOffset = MediaQuery.viewInsetsOf(context).bottom;

    final isLastPage = state.currentPage == OnboardingController.lastPage;

    return Scaffold(
      backgroundColor: Colors.white,
      resizeToAvoidBottomInset: false,
      body: SafeArea(
        child: Column(
          children: [
            const SizedBox(height: 16),

            Expanded(
              key: const ValueKey('onboarding_page_view'),
              child: PageView(
                controller: controller.pageController,
                onPageChanged: controller.onPageChanged,
                physics: const NeverScrollableScrollPhysics(),
                children: const [
                  StepName(),
                  StepPhone(),
                  StepAddress(),
                ],
              ),
            ),

            OnboardingDots(currentPage: state.currentPage),
            const SizedBox(height: 20),

            Transform.translate(
              offset: Offset(0, -keyboardOffset),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
                child: OnboardingBottomNav(
                  currentPage: state.currentPage,
                  isLoading: state.isSubmitting,
                  onBack: controller.previousPage,
                  onNext: isLastPage
                      ? () => _submit(context, controller)
                      : () => _next(context, controller),
                ),
              ),
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }
}
