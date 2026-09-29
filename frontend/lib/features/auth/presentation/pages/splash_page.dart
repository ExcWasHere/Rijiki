import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/constants/app_strings.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../features/auth/presentation/controllers/splash_controller.dart';
import '../../../../features/auth/presentation/widgets/splash_logo.dart';
import '../../../../shared/widgets/error_state.dart';

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

    return Scaffold(
      backgroundColor: AppColors.primary,
      body: SafeArea(
        child: state.hasError
            ? _ErrorView(
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
    return Column(
      children: [
        const Expanded(child: Center(child: SplashLogo())),
        const SizedBox(
          width: 24,
          height: 24,
          child: CircularProgressIndicator(
            strokeWidth: 2.5,
            color: AppColors.onPrimary,
          ),
        ),
        const SizedBox(height: AppSpacing.md),
        Text(
          AppStrings.splashLoading,
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: AppColors.onPrimary.withValues(alpha: 0.8),
              ),
        ),
        const SizedBox(height: AppSpacing.xl),
      ],
    );
  }
}

class _ErrorView extends StatelessWidget {
  const _ErrorView({required this.onRetry});

  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Container(
        margin: const EdgeInsets.all(AppSpacing.lg),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
        ),
        child: ErrorState(
          message: AppStrings.splashErrorTitle,
          onRetry: onRetry,
        ),
      ),
    );
  }
}