import 'package:flutter/material.dart';

abstract final class AppTypography {
  /// Isi nama family kalau pakai font kustom (daftarkan di pubspec.yaml,
  /// file font di assets/fonts/). null = font bawaan platform.
  static const String? fontFamily = null;

  static const TextTheme textTheme = TextTheme(
    headlineLarge: TextStyle(fontSize: 32, fontWeight: FontWeight.w700, height: 1.25),
    headlineMedium: TextStyle(fontSize: 26, fontWeight: FontWeight.w700, height: 1.25),
    headlineSmall: TextStyle(fontSize: 22, fontWeight: FontWeight.w600, height: 1.3),
    titleLarge: TextStyle(fontSize: 20, fontWeight: FontWeight.w600, height: 1.3),
    titleMedium: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, height: 1.4),
    titleSmall: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, height: 1.4),
    bodyLarge: TextStyle(fontSize: 16, fontWeight: FontWeight.w400, height: 1.5),
    bodyMedium: TextStyle(fontSize: 14, fontWeight: FontWeight.w400, height: 1.5),
    bodySmall: TextStyle(fontSize: 12, fontWeight: FontWeight.w400, height: 1.4),
    labelLarge: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, height: 1.2),
    labelMedium: TextStyle(fontSize: 12, fontWeight: FontWeight.w500, height: 1.2),
    labelSmall: TextStyle(fontSize: 11, fontWeight: FontWeight.w500, height: 1.2),
  );
}