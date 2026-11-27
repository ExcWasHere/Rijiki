import 'package:flutter/material.dart';
import 'package:rijiki/core/theme/app_colors.dart';
import 'package:rijiki/core/theme/app_spacing.dart';
import 'package:rijiki/shared/widgets/loading_skeleton.dart';

class NetworkImageBox extends StatelessWidget {
  const NetworkImageBox({
    super.key,
    required this.url,
    this.width,
    this.height,
    this.radius = AppSpacing.radiusSm,
    this.fit = BoxFit.cover,
    this.headers,
  });

  final String url;
  final double? width;
  final double? height;
  final double radius;
  final BoxFit fit;
  final Map<String, String>? headers;

  @override
  Widget build(BuildContext context) {
    final pixelRatio = MediaQuery.devicePixelRatioOf(context);
    // Hanya satu dimensi agar rasio asli tetap terjaga (fit cover/contain).
    final cacheWidth = width != null
        ? (width! * pixelRatio).round()
        : null;
    final cacheHeight = cacheWidth == null && height != null
        ? (height! * pixelRatio).round()
        : null;

    return ClipRRect(
      borderRadius: BorderRadius.circular(radius),
      child: SizedBox(
        width: width,
        height: height,
        child: Image.network(
          url,
          fit: fit,
          headers: headers,
          cacheWidth: cacheWidth,
          cacheHeight: cacheHeight,
          loadingBuilder: (context, child, progress) =>
              progress == null ? child : const LoadingSkeleton(radius: 0),
          errorBuilder: (context, error, stackTrace) => ColoredBox(
            color: AppColors.outline.withValues(alpha: 0.15),
            child: const Center(
              child: Icon(
                Icons.image_not_supported_outlined,
                color: AppColors.onSurfaceVariant,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
