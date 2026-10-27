import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:rijiki/app/providers.dart';
import 'package:rijiki/core/network/api_endpoint.dart';
import 'package:rijiki/core/theme/app_colors.dart';
import 'package:rijiki/shared/widgets/loading_skeleton.dart';

Duration? _noRetry(int retryCount, Object error) => null;

final privateImageProvider = FutureProvider.family<Uint8List, String>((
  ref,
  key,
) {
  return ref
      .watch(apiClientProvider)
      .getBytes(ApiEndpoints.privateMedia(key), auth: true);
}, retry: _noRetry);

class PrivateImage extends ConsumerWidget {
  const PrivateImage({super.key, required this.imageKey, this.fit = BoxFit.cover});

  final String imageKey;
  final BoxFit fit;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final image = ref.watch(privateImageProvider(imageKey));

    return image.when(
      loading: () => const LoadingSkeleton(radius: 0),
      error: (_, _) => _Unavailable(
        onRetry: () => ref.invalidate(privateImageProvider(imageKey)),
      ),
      data: (bytes) => Image.memory(
        bytes,
        fit: fit,
        gaplessPlayback: true,
        errorBuilder: (_, _, _) => const _Unavailable(),
      ),
    );
  }
}

class _Unavailable extends StatelessWidget {
  const _Unavailable({this.onRetry});

  final VoidCallback? onRetry;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return InkWell(
      onTap: onRetry,
      child: ColoredBox(
        color: AppColors.outline.withValues(alpha: 0.15),
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                onRetry == null
                    ? Icons.image_not_supported_outlined
                    : Icons.refresh_rounded,
                color: AppColors.onSurfaceVariant,
              ),
              const SizedBox(height: 4),
              Text(
                onRetry == null ? 'Foto tidak tersedia' : 'Ketuk untuk coba lagi',
                textAlign: TextAlign.center,
                style: textTheme.bodySmall?.copyWith(
                  color: AppColors.onSurfaceVariant,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
