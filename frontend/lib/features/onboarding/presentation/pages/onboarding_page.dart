import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:rijiki/app/router/route_paths.dart';
import 'package:rijiki/core/theme/app_spacing.dart';
import 'package:rijiki/features/onboarding/presentation/controllers/onboarding_controller.dart';
import 'package:rijiki/features/onboarding/presentation/widgets/components/onboarding_bottom_nav.dart';
import 'package:rijiki/features/onboarding/presentation/widgets/components/onboarding_dots.dart';
import 'package:rijiki/features/onboarding/presentation/widgets/steps/step_address.dart';
import 'package:rijiki/features/onboarding/presentation/widgets/steps/step_delivery.dart';
import 'package:rijiki/features/onboarding/presentation/widgets/steps/step_name.dart';
import 'package:rijiki/features/onboarding/presentation/widgets/steps/step_phone.dart';
import 'package:rijiki/features/onboarding/presentation/widgets/steps/step_problems.dart';
import 'package:rijiki/features/onboarding/presentation/widgets/steps/step_smart_care.dart';
import 'package:rijiki/features/onboarding/presentation/widgets/steps/step_welcome.dart';

class OnboardingPage extends ConsumerWidget {
  const OnboardingPage({super.key});

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
                  Padding(
                    padding: EdgeInsets.symmetric(horizontal: AppSpacing.lg),
                    child: StepWelcome(),
                  ),
                  StepName(),
                  StepPhone(),
                  StepAddress(),
                  Padding(
                    padding: EdgeInsets.symmetric(horizontal: AppSpacing.lg),
                    child: StepProblems(),
                  ),
                  Padding(
                    padding: EdgeInsets.symmetric(horizontal: AppSpacing.lg),
                    child: StepSmartCare(),
                  ),
                  Padding(
                    padding: EdgeInsets.symmetric(horizontal: AppSpacing.lg),
                    child: StepDelivery(),
                  ),
                ],
              ),
            ),

            if (state.currentPage != 4) ...[
              OnboardingDots(currentPage: state.currentPage),
              const SizedBox(height: 20),
            ] else ...[
              const SizedBox(height: 12),
            ],

            Transform.translate(
              offset: Offset(0, -keyboardOffset),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
                child: OnboardingBottomNav(
                  currentPage: state.currentPage,
                  onBack: controller.previousPage,
                  onNext: isLastPage
                      ? () async {
                          await controller.complete();
                          if (context.mounted) {
                            context.go(RoutePaths.customerHome);
                          }
                        }
                      : controller.nextPage,
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
