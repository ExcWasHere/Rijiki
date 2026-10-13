import 'package:flutter/material.dart';
import 'package:rijiki/core/constants/app_strings.dart';
import 'package:rijiki/core/theme/app_colors.dart';
import 'package:rijiki/core/theme/app_spacing.dart';

class ErrorState extends StatelessWidget {
  const ErrorState({
    super.key,
    this.title,
    this.message = 'Data gagal dimuat. Coba lagi ya.',
    this.icon = Icons.wifi_off_rounded,
    this.isRetrying = false,
    this.onRetry,
  });

  final String? title;
  final String message;
  final IconData icon;
  final bool isRetrying;
  final VoidCallback? onRetry;

  static const Duration _fade = Duration(milliseconds: 250);

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final accent = isRetrying ? AppColors.primaryDark : AppColors.error;
    final heading = isRetrying ? AppStrings.retrying : title;
    final body = isRetrying ? AppStrings.retryingHint : message;

    return Padding(
      padding: const EdgeInsets.all(AppSpacing.md),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          AnimatedContainer(
            duration: _fade,
            width: 52,
            height: 52,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: accent.withValues(alpha: 0.10),
              shape: BoxShape.circle,
            ),
            child: AnimatedSwitcher(
              duration: _fade,
              child: isRetrying
                  ? SizedBox(
                      key: const ValueKey('retrying'),
                      width: 24,
                      height: 24,
                      child: CircularProgressIndicator(
                        strokeWidth: 2.5,
                        color: accent,
                      ),
                    )
                  : Icon(icon, key: ValueKey(icon), color: accent),
            ),
          ),
          const SizedBox(height: AppSpacing.sm + 4),
          AnimatedSwitcher(
            duration: _fade,
            child: Column(
              key: ValueKey(isRetrying),
              mainAxisSize: MainAxisSize.min,
              children: [
                if (heading != null) ...[
                  Text(
                    heading,
                    style: textTheme.titleMedium,
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: AppSpacing.xs),
                ],
                Text(
                  body,
                  style: textTheme.bodyMedium?.copyWith(
                    color: AppColors.onSurfaceVariant,
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
          if (onRetry != null) ...[
            const SizedBox(height: AppSpacing.md),
            OutlinedButton.icon(
              onPressed: isRetrying ? null : onRetry,
              icon: const Icon(Icons.refresh_rounded, size: AppSpacing.iconSm),
              label: Text(
                isRetrying ? AppStrings.retryingShort : AppStrings.retry,
              ),
              style: OutlinedButton.styleFrom(
                minimumSize: const Size(0, 44),
                padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
              ),
            ),
          ],
        ],
      ),
    );
  }
}
