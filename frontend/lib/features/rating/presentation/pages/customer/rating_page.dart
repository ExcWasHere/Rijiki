import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'package:rijiki/core/theme/app_colors.dart';
import 'package:rijiki/core/theme/app_spacing.dart';
import 'package:rijiki/features/order/presentation/controllers/order_detail_controller.dart';
import 'package:rijiki/features/order/presentation/controllers/order_list_controller.dart';
import 'package:rijiki/features/rating/presentation/controllers/rating_submit_controller.dart';

class RatingPage extends ConsumerStatefulWidget {
  const RatingPage({super.key, required this.orderId});

  final String orderId;

  @override
  ConsumerState<RatingPage> createState() => _RatingPageState();
}

class _RatingPageState extends ConsumerState<RatingPage> {
  final TextEditingController _comment = TextEditingController();
  final ImagePicker _picker = ImagePicker();

  static const List<String> _labels = [
    'Kurang puas',
    'Cukup',
    'Bagus',
    'Sangat bagus',
    'Luar biasa',
  ];

  @override
  void dispose() {
    _comment.dispose();
    super.dispose();
  }

  Future<void> _pickPhoto(ImageSource source) async {
    final messenger = ScaffoldMessenger.of(context);
    try {
      // Dikompres di perangkat supaya unggahan ringan (batas server 5 MB).
      final picked = await _picker.pickImage(
        source: source,
        imageQuality: 80,
        maxWidth: 1600,
      );
      if (picked != null && mounted) {
        ref.read(ratingSubmitProvider.notifier).setPhoto(picked.path);
      }
    } catch (_) {
      messenger
        ..hideCurrentSnackBar()
        ..showSnackBar(
          const SnackBar(content: Text('Foto tidak bisa dibuka. Coba lagi ya.')),
        );
    }
  }

  Future<void> _showPhotoSources() {
    return showModalBottomSheet<void>(
      context: context,
      backgroundColor: AppColors.surface,
      builder: (sheetContext) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.photo_camera_rounded),
              title: const Text('Ambil foto'),
              onTap: () {
                Navigator.pop(sheetContext);
                _pickPhoto(ImageSource.camera);
              },
            ),
            ListTile(
              leading: const Icon(Icons.photo_library_rounded),
              title: const Text('Pilih dari galeri'),
              onTap: () {
                Navigator.pop(sheetContext);
                _pickPhoto(ImageSource.gallery);
              },
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _submit() async {
    final messenger = ScaffoldMessenger.of(context);
    final router = GoRouter.of(context);
    FocusScope.of(context).unfocus();

    final result = await ref
        .read(ratingSubmitProvider.notifier)
        .submit(orderId: widget.orderId, comment: _comment.text);
    if (result == null) return;

    ref.invalidate(orderDetailProvider(widget.orderId));
    ref.invalidate(ordersProvider);

    final message = result.alreadyRated
        ? 'Rating untuk order ini sudah tercatat.'
        : (result.pointsAwarded > 0
              ? 'Terima kasih! Kamu dapat ${result.pointsAwarded} poin.'
              : 'Terima kasih atas ratingmu!');
    messenger
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(message)));
    if (mounted) router.pop();
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(ratingSubmitProvider);
    final notifier = ref.read(ratingSubmitProvider.notifier);
    final textTheme = Theme.of(context).textTheme;
    final busy = state.isSubmitting;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(title: const Text('Beri rating')),
      body: ListView(
        keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
        padding: const EdgeInsets.all(AppSpacing.lg),
        children: [
          Text(
            'Bagaimana hasil perawatan sepatumu?',
            style: textTheme.titleMedium,
          ),
          const SizedBox(height: AppSpacing.md),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              for (var star = 1; star <= 5; star++)
                IconButton(
                  iconSize: 40,
                  onPressed: busy ? null : () => notifier.setRating(star),
                  icon: Icon(
                    star <= state.rating
                        ? Icons.star_rounded
                        : Icons.star_outline_rounded,
                    color: AppColors.accent,
                  ),
                ),
            ],
          ),
          SizedBox(
            height: 24,
            child: Center(
              child: Text(
                state.rating == 0 ? 'Ketuk bintang untuk menilai' : _labels[state.rating - 1],
                style: textTheme.bodyMedium?.copyWith(
                  color: AppColors.onSurfaceVariant,
                ),
              ),
            ),
          ),
          const SizedBox(height: AppSpacing.lg),
          TextField(
            controller: _comment,
            enabled: !busy,
            minLines: 3,
            maxLines: 5,
            maxLength: 500,
            textCapitalization: TextCapitalization.sentences,
            decoration: const InputDecoration(
              labelText: 'Komentar (opsional)',
              alignLabelWithHint: true,
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
          if (state.photoPath == null)
            OutlinedButton.icon(
              onPressed: busy ? null : _showPhotoSources,
              icon: const Icon(Icons.add_a_photo_outlined),
              label: const Text('Tambah foto sepatu (opsional)'),
            )
          else
            Stack(
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
                  child: Image.file(
                    File(state.photoPath!),
                    height: 200,
                    width: double.infinity,
                    fit: BoxFit.cover,
                  ),
                ),
                Positioned(
                  top: 8,
                  right: 8,
                  child: IconButton.filled(
                    onPressed: busy ? null : notifier.clearPhoto,
                    icon: const Icon(Icons.close_rounded),
                  ),
                ),
              ],
            ),
          const SizedBox(height: AppSpacing.sm),
          Text(
            'Komentar dan foto yang kamu kirim bisa ditampilkan Rijiki sebagai '
            'testimoni di aplikasi, dengan namamu disingkat (mis. "Rina A.").',
            style: textTheme.bodySmall?.copyWith(
              color: AppColors.onSurfaceVariant,
            ),
          ),
          if (state.error != null) ...[
            const SizedBox(height: AppSpacing.md),
            Text(
              state.error!,
              style: textTheme.bodyMedium?.copyWith(
                color: Theme.of(context).colorScheme.error,
              ),
            ),
          ],
          const SizedBox(height: AppSpacing.lg),
          FilledButton(
            onPressed: state.canSubmit ? _submit : null,
            child: busy
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: AppColors.onPrimary,
                    ),
                  )
                : const Text('Kirim rating'),
          ),
        ],
      ),
    );
  }
}
