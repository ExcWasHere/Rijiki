import 'dart:io';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:rijiki/core/theme/app_colors.dart';
import 'package:rijiki/core/theme/app_spacing.dart';

class ImagePickerField extends StatelessWidget {
  const ImagePickerField({
    super.key,
    required this.path,
    required this.onChanged,
    this.label = 'Lampirkan foto',
    this.attachedLabel = 'Foto terlampir',
    this.enabled = true,
  });

  final String? path;
  final ValueChanged<String?> onChanged;
  final String label;
  final String attachedLabel;
  final bool enabled;

  @override
  Widget build(BuildContext context) {
    final current = path;
    return current == null
        ? _PickButton(
            label: label,
            onTap: enabled ? () => _pick(context) : null,
          )
        : _Attached(
            path: current,
            label: attachedLabel,
            onChange: enabled ? () => _pick(context) : null,
            onRemove: enabled ? () => onChanged(null) : null,
          );
  }

  Future<void> _pick(BuildContext context) async {
    final source = await showModalBottomSheet<ImageSource>(
      context: context,
      showDragHandle: true,
      builder: (sheetContext) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.photo_camera_rounded),
              title: const Text('Kamera'),
              onTap: () => Navigator.pop(sheetContext, ImageSource.camera),
            ),
            ListTile(
              leading: const Icon(Icons.photo_library_rounded),
              title: const Text('Galeri'),
              onTap: () => Navigator.pop(sheetContext, ImageSource.gallery),
            ),
          ],
        ),
      ),
    );
    if (source == null) return;

    try {
      final picked = await ImagePicker().pickImage(
        source: source,
        imageQuality: 85,
        maxWidth: 1600,
        maxHeight: 1600,
      );
      if (picked != null) onChanged(picked.path);
    } catch (_) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(
          const SnackBar(content: Text('Foto gagal diambil. Coba lagi ya.')),
        );
    }
  }
}

class _PickButton extends StatelessWidget {
  const _PickButton({required this.label, required this.onTap});

  final String label;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return Material(
      color: AppColors.surface,
      shape: StadiumBorder(
        side: BorderSide(color: AppColors.outline.withValues(alpha: 0.4)),
      ),
      child: InkWell(
        customBorder: const StadiumBorder(),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(12, 8, 14, 8),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(
                Icons.attach_file_rounded,
                size: AppSpacing.iconSm,
                color: AppColors.primaryDark,
              ),
              const SizedBox(width: 6),
              Text(
                label,
                style: textTheme.labelLarge?.copyWith(
                  color: AppColors.onSurface,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _Attached extends StatelessWidget {
  const _Attached({
    required this.path,
    required this.label,
    required this.onChange,
    required this.onRemove,
  });

  final String path;
  final String label;
  final VoidCallback? onChange;
  final VoidCallback? onRemove;

  Widget _brokenImage() => Container(
    width: 48,
    height: 48,
    color: AppColors.outline.withValues(alpha: 0.15),
    child: const Icon(
      Icons.image_not_supported_outlined,
      color: AppColors.onSurfaceVariant,
    ),
  );

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppSpacing.sm),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
        border: Border.all(color: AppColors.outline.withValues(alpha: 0.4)),
      ),
      child: Row(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
            child: path.startsWith('http')
                ? Image.network(
                    path,
                    width: 48,
                    height: 48,
                    fit: BoxFit.cover,
                    errorBuilder: (_, _, _) => _brokenImage(),
                  )
                : Image.file(
                    File(path),
                    width: 48,
                    height: 48,
                    fit: BoxFit.cover,
                    errorBuilder: (_, _, _) => _brokenImage(),
                  ),
          ),
          const SizedBox(width: AppSpacing.sm + 4),
          Expanded(child: Text(label, style: textTheme.titleSmall)),
          TextButton(onPressed: onChange, child: const Text('Ganti')),
          IconButton(
            tooltip: 'Hapus',
            onPressed: onRemove,
            icon: const Icon(Icons.close_rounded),
            color: AppColors.onSurfaceVariant,
          ),
        ],
      ),
    );
  }
}
