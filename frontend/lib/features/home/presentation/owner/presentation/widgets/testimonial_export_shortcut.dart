import 'package:flutter/material.dart';
import 'package:rijiki/core/theme/app_colors.dart';
import 'package:rijiki/core/theme/app_spacing.dart';

/// Shortcut ke fitur Rekap Testimoni Foto (PRD Bagian 13.2 dan 20.2).
/// Aksi unduh yang sebenarnya dikerjakan bersama modul rating/testimoni;
/// sementara [onTap] bisa diisi pesan "segera hadir".
class TestimonialExportShortcut extends StatelessWidget {
  const TestimonialExportShortcut({super.key, this.onTap});

  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final radius = BorderRadius.circular(AppSpacing.radiusLg);

    return Material(
      color: AppColors.rijikiOrange.withValues(alpha: 0.1),
      borderRadius: radius,
      child: InkWell(
        borderRadius: radius,
        onTap: onTap,
        child: Ink(
          padding: const EdgeInsets.all(AppSpacing.md),
          decoration: BoxDecoration(
            borderRadius: radius,
            border: Border.all(
              color: AppColors.rijikiOrange.withValues(alpha: 0.35),
            ),
          ),
          child: Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: AppColors.rijikiOrange,
                  borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
                ),
                child: const Icon(
                  Icons.photo_library_rounded,
                  color: Colors.white,
                ),
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Rekap testimoni foto', style: textTheme.titleSmall),
                    const SizedBox(height: 2),
                    Text(
                      'Unduh foto dan ulasan pelanggan untuk konten promosi.',
                      style: textTheme.bodySmall?.copyWith(
                        color: AppColors.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              const Icon(
                Icons.download_rounded,
                color: AppColors.onSurfaceVariant,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
