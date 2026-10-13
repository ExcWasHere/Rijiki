import 'package:flutter/material.dart';
import 'package:rijiki/core/theme/app_colors.dart';
import 'package:rijiki/core/theme/app_spacing.dart';

class ScanCtaCard extends StatelessWidget {
  const ScanCtaCard({super.key, required this.onScan});

  final VoidCallback onScan;

  static const String _bannerAsset = 'assets/images/banner2.jpeg';
  static const double _textMaxWidth = 210;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return ClipRRect(
      borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
      child: Container(
        width: double.infinity,
        constraints: const BoxConstraints(minHeight: 196),
        color: AppColors.primary,
        child: Stack(
          children: [
            Positioned.fill(
              child: Image.asset(
                _bannerAsset,
                fit: BoxFit.cover,
                alignment: Alignment.centerRight,
                excludeFromSemantics: true,
                errorBuilder: (_, _, _) => const SizedBox.shrink(),
              ),
            ),
            Positioned.fill(
              child: DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.centerLeft,
                    end: Alignment.centerRight,
                    colors: [
                      AppColors.primary.withValues(alpha: 0.96),
                      AppColors.primary.withValues(alpha: 0.82),
                      AppColors.primary.withValues(alpha: 0),
                    ],
                    stops: const [0, 0.5, 0.85],
                  ),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(AppSpacing.lg - 4),
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: _textMaxWidth),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Sepatumu butuh perawatan apa?',
                      style: textTheme.titleLarge?.copyWith(
                        color: AppColors.onPrimary,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      'Foto sepatumu, nanti kami kasih saran layanan yang paling pas.',
                      style: textTheme.bodyMedium?.copyWith(
                        color: AppColors.onPrimary,
                      ),
                    ),
                    const SizedBox(height: AppSpacing.md),
                    FilledButton.icon(
                      onPressed: onScan,
                      icon: const Icon(Icons.photo_camera_rounded, size: 20),
                      label: const Text('Scan sepatu'),
                      style: FilledButton.styleFrom(
                        backgroundColor: AppColors.rijikiOrange,
                        foregroundColor: AppColors.onPrimary,
                        minimumSize: const Size(0, 44),
                        padding: const EdgeInsets.symmetric(
                          horizontal: AppSpacing.md,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}