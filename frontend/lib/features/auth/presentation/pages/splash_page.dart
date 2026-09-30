import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '/../core/constants/app_constants.dart';
import '/../core/constants/app_strings.dart';
import '/../core/theme/app_colors.dart';
import '/../core/theme/app_spacing.dart';
import '/../features/auth/presentation/controllers/splash_controller.dart';
import '/../features/auth/presentation/widgets/splash_collab_badge.dart';
import '/../features/auth/presentation/widgets/splash_content.dart';
import '/../features/auth/presentation/widgets/splash_loading_dots.dart';
import '/../shared/widgets/error_state.dart';

/// Halaman pertama aplikasi. Hanya menyusun layout; proses startup ada di
/// [SplashController], tahapan animasi logo/huruf ada di [SplashContent].
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
      backgroundColor: AppColors.background,
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
    // Badge kolaborasi muncul sedikit sebelum dots, keduanya setelah
    // animasi utama (ikon + huruf + tagline) selesai.
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

/// Menahan [child] transparan sampai [delay] berlalu, lalu fade-in.
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
  const _ErrorView({required this.onRetry});

  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Container(
        margin: const EdgeInsets.all(AppSpacing.lg),
        padding: const EdgeInsets.all(AppSpacing.lg),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
          border: Border.all(color: AppColors.outline),
        ),
        child: ErrorState(
          message: AppStrings.splashErrorTitle,
          onRetry: onRetry,
        ),
      ),
    );
  }
}