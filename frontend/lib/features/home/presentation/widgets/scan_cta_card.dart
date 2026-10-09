import 'package:flutter/material.dart';
import 'package:rijiki/core/theme/app_colors.dart';
import 'package:rijiki/core/theme/app_spacing.dart';

class ScanCtaCard extends StatelessWidget {
  const ScanCtaCard({super.key, required this.onScan});

  final VoidCallback onScan;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return ClipRRect(
      borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
      child: Container(
        width: double.infinity,
        color: AppColors.primary,
        child: Stack(
          children: [
            Positioned(
              right: -22,
              bottom: -26,
              child: Icon(
                Icons.document_scanner_rounded,
                size: 150,
                color: AppColors.onPrimary.withValues(alpha: 0.10),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(AppSpacing.lg - 4),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Sepatumu butuh perawatan apa?',
                    style: textTheme.titleLarge?.copyWith(
                      color: AppColors.onPrimary,
                    ),
                  ),
                  const SizedBox(height: 6),
                  ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 240),
                    child: Text(
                      'Foto sepatumu, nanti kami kasih saran layanan yang paling pas.',
                      style: textTheme.bodyMedium?.copyWith(
                        color: AppColors.onPrimary,
                      ),
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
          ],
        ),
      ),
    );
  }
}
