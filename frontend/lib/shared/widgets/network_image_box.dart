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
    return ClipRRect(
      borderRadius: BorderRadius.circular(radius),
      child: SizedBox(
        width: width,
        height: height,
        child: Image.network(
          url,
          fit: fit,
          headers: headers,
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
