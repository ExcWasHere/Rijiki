import 'package:flutter/material.dart';

/// Satu-satunya sumber warna. Semua nilai brand masih placeholder.
abstract final class AppColors {
  // Brand
  static const Color primary = Color(0xFF87CEEB);       // Sky Blue
  static const Color primaryDark = Color(0xFF46A0C3);   // Darker Sky Blue
  static const Color onPrimary = Color(0xFF193746);     // Dark Navy

  static const Color secondary = Color(0xFFFFFFFF);     // White
  static const Color onSecondary = Color(0xFF283237);   // Dark Gray

  // Accent / Third Color
  static const Color accent = Color(0xFFFFB74D);        // Light Orange

  // Neutral
  static const Color background = Color(0xFFF5FBFD);    // Very Light Blue
  static const Color surface = Color(0xFFFFFFFF);       // White
  static const Color onSurface = Color(0xFF232D32);    // Dark Gray
  static const Color onSurfaceVariant = Color(0xFF607D86);
  static const Color outline = Color(0xFF96B4BE);      // Blue Gray

  // Status
  static const Color success = Color(0xFF4CAF50);
  static const Color warning = Color(0xFFFFA726);
  static const Color error = Color(0xFFD32F2F);
  static const Color info = Color(0xFF2196F3);
}