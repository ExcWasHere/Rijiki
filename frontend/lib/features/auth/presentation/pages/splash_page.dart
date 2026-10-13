import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:rijiki/core/constants/app_constants.dart';
import 'package:rijiki/core/error/failure_presenter.dart';
import 'package:rijiki/core/theme/app_colors.dart';
import 'package:rijiki/core/theme/app_spacing.dart';
import 'package:rijiki/features/auth/presentation/controllers/splash_controller.dart';
import 'package:rijiki/features/auth/presentation/widgets/splash_collab_badge.dart';
import 'package:rijiki/features/auth/presentation/widgets/splash_content.dart';
import 'package:rijiki/features/auth/presentation/widgets/splash_loading_dots.dart';
import 'package:rijiki/shared/widgets/error_state.dart';

class SplashPage extends ConsumerWidget {
  const SplashPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    ref.listen<AsyncValue<String>>(splashControllerProvider, (_, next) {
      next.whenData((route) {
        if (context.mounted) context.go(route);
      });
    });

    final state = ref.watch(splashControllerProvider);
    final isRetrying = state.isLoading && state.hasError;

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: state.hasError
            ? _ErrorView(
                error: state.error,
                isRetrying: isRetrying,
                onRetry: () =>
                    ref.read(splashControllerProvider.notifier).retry(),
              )
            : const _LoadingView(),
      ),
    );
  }
}

class _LoadingView extends StatelessWidget {
  const _LoadingView();

  @override
  Widget build(BuildContext context) {
    final collabDelay = AppConstants.splashStageDuration * 0.95;
    final dotsDelay = AppConstants.splashStageDuration * 1.25;

    return Column(
      children: [
        const Expanded(child: Center(child: SplashContent())),
        _DelayedFadeIn(
          delay: collabDelay,
          child: const Padding(
            padding: EdgeInsets.only(bottom: AppSpacing.lg),
            child: SplashCollabBadge(),
          ),
        ),
        _DelayedFadeIn(
          delay: dotsDelay,
          child: const Padding(
            padding: EdgeInsets.only(bottom: AppSpacing.xl),
            child: SplashLoadingDots(),
          ),
        ),
      ],
    );
  }
}

class _DelayedFadeIn extends StatelessWidget {
  const _DelayedFadeIn({required this.delay, required this.child});

  final Duration delay;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<void>(
      future: Future<void>.delayed(delay),
      builder: (context, snapshot) {
        final visible = snapshot.connectionState == ConnectionState.done;
        return AnimatedOpacity(
          opacity: visible ? 1 : 0,
          duration: const Duration(milliseconds: 300),
          child: child,
        );
      },
    );
  }
}

class _ErrorView extends StatelessWidget {
  const _ErrorView({
    required this.error,
    required this.isRetrying,
    required this.onRetry,
  });

  final Object? error;
  final bool isRetrying;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    final view = FailurePresenter.describe(error);

    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 340),
        child: Container(
          margin: const EdgeInsets.all(AppSpacing.lg),
          padding: const EdgeInsets.all(AppSpacing.lg),
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
            border: Border.all(color: AppColors.outline),
          ),
          child: ErrorState(
            icon: view.icon,
            title: view.title,
            message: view.message,
            isRetrying: isRetrying,
            onRetry: onRetry,
          ),
        ),
      ),
    );
  }
}
