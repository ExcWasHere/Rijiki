import 'dart:io';

import 'package:flutter/material.dart';
import 'package:rijiki/core/theme/app_colors.dart';

/// Avatar profil: foto dari R2 bila ada, selain itu inisial nama.
class ProfileAvatar extends StatelessWidget {
  const ProfileAvatar({
    super.key,
    required this.name,
    required this.avatarUrl,
    this.radius = 32,
    this.backgroundColor = AppColors.primaryDark,
    this.foregroundColor = Colors.white,
  });

  final String name;
  final String? avatarUrl;
  final double radius;
  final Color backgroundColor;
  final Color foregroundColor;

  String get _initials {
    final words = name
        .trim()
        .split(RegExp(r'\s+'))
        .where((word) => word.isNotEmpty)
        .toList();
    if (words.isEmpty) return 'R';
    if (words.length == 1) return words.first[0].toUpperCase();
    return '${words.first[0]}${words.last[0]}'.toUpperCase();
  }

  @override
  Widget build(BuildContext context) {
    final fallback = ColoredBox(
      color: backgroundColor,
      child: Center(
        child: Text(
          _initials,
          style: TextStyle(
            color: foregroundColor,
            fontWeight: FontWeight.w700,
            fontSize: radius * 0.6,
          ),
        ),
      ),
    );

    final url = avatarUrl;
    // Decode hanya sebesar kotak avatar supaya hemat memori.
    final cacheWidth = (radius * 2 * MediaQuery.devicePixelRatioOf(context))
        .round();
    final Widget content;
    if (url == null || url.isEmpty) {
      content = fallback;
    } else if (url.startsWith('http')) {
      content = Image.network(
        url,
        fit: BoxFit.cover,
        cacheWidth: cacheWidth,
        errorBuilder: (_, _, _) => fallback,
      );
    } else {
      // Mock mode menyimpan path file lokal sebagai avatar.
      content = Image.file(
        File(url),
        fit: BoxFit.cover,
        cacheWidth: cacheWidth,
        errorBuilder: (_, _, _) => fallback,
      );
    }

    return SizedBox(
      width: radius * 2,
      height: radius * 2,
      child: ClipOval(child: content),
    );
  }
}
