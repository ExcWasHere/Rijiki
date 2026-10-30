import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

/// [maxSize] = sisi terpanjang (px), [quality] = kualitas JPG 0-100.
/// Default sama seperti sebelumnya; avatar memakai 512 / 85 (PRD #30).
Future<String?> pickImageFromSheet(
  BuildContext context, {
  int maxSize = 1600,
  int quality = 80,
}) async {
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
  if (source == null) return null;

  try {
    final picked = await ImagePicker().pickImage(
      source: source,
      imageQuality: quality,
      maxWidth: maxSize.toDouble(),
      maxHeight: maxSize.toDouble(),
    );
    return picked?.path;
  } catch (_) {
    if (!context.mounted) return null;
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        const SnackBar(content: Text('Foto gagal diambil. Coba lagi ya.')),
      );
    return null;
  }
}
