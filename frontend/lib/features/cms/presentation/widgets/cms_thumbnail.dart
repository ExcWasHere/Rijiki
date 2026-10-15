import 'dart:io';

import 'package:flutter/material.dart';
import 'package:rijiki/core/theme/app_spacing.dart';

class CmsThumbnail extends StatelessWidget {
  const CmsThumbnail({
    super.key,
    required this.url,
    required this.fallbackIcon,
    required this.fallbackColor,
    this.size = 56,
  });

  final String? url;
  final IconData fallbackIcon;
  final Color fallbackColor;
  final double size;

  @override
  Widget build(BuildContext context) {
    final fallback = Container(
      width: size,
      height: size,
      color: fallbackColor.withValues(alpha: 0.14),
      child: Icon(fallbackIcon, color: fallbackColor, size: size * 0.45),
    );
    final source = url;

    Widget child = fallback;
    if (source != null && source.isNotEmpty) {
      child = source.startsWith('http')
          ? Image.network(
              source,
              width: size,
              height: size,
              fit: BoxFit.cover,
              errorBuilder: (_, _, _) => fallback,
            )
          : Image.file(
              File(source),
              width: size,
              height: size,
              fit: BoxFit.cover,
              errorBuilder: (_, _, _) => fallback,
            );
    }

    return ClipRRect(
      borderRadius: BorderRadius.circular(AppSpacing.radiusMd - 2),
      child: SizedBox(width: size, height: size, child: child),
    );
  }
}
