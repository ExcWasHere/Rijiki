import 'package:flutter/material.dart';
import 'package:rijiki/core/theme/app_colors.dart';
import 'package:rijiki/core/theme/app_spacing.dart';

Future<void> showScanTipsSheet(BuildContext context) {
  return showModalBottomSheet<void>(
    context: context,
    showDragHandle: true,
    backgroundColor: AppColors.surface,
    builder: (context) => const _ScanTipsContent(),
  );
}

class _ScanTipsContent extends StatelessWidget {
  const _ScanTipsContent();

  static const List<(IconData, String)> _tips = [
    (Icons.wb_sunny_outlined, 'Cari tempat terang dan hindari bayangan di sepatu.'),
    (Icons.crop_free_rounded, 'Pastikan seluruh sepatu masuk ke dalam bingkai.'),
    (Icons.flip_camera_android_outlined, 'Ambil dari samping supaya bentuk dan sol terlihat.'),
    (Icons.looks_one_outlined, 'Satu sepatu per foto biar hasilnya lebih akurat.'),
  ];

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(
          AppSpacing.lg,
          0,
          AppSpacing.lg,
          AppSpacing.md,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Tips foto yang baik', style: textTheme.titleLarge),
            const SizedBox(height: AppSpacing.md),
            for (final (icon, text) in _tips)
              Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(icon, size: 22, color: AppColors.primaryDark),
                    const SizedBox(width: 12),
                    Expanded(child: Text(text, style: textTheme.bodyMedium)),
                  ],
                ),
              ),
            const SizedBox(height: AppSpacing.sm),
            FilledButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Mengerti'),
            ),
          ],
        ),
      ),
    );
  }
}
