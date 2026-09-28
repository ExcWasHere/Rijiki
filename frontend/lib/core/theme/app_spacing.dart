import 'package:flutter/material.dart';

abstract final class AppSpacing {
  static const double xs = 4;
  static const double sm = 8;
  static const double md = 16;
  static const double lg = 24;
  static const double xl = 32;
  static const double xxl = 48;

  static const double radiusSm = 8;
  static const double radiusMd = 12;
  static const double radiusLg = 20;

  static const double iconSm = 18;
  static const double iconMd = 24;
  static const double iconLg = 32;

  static const double buttonHeight = 52;

  static const List<BoxShadow> shadowSm = [
    BoxShadow(color: Color(0x14000000), blurRadius: 6, offset: Offset(0, 2)),
  ];
  static const List<BoxShadow> shadowMd = [
    BoxShadow(color: Color(0x1F000000), blurRadius: 16, offset: Offset(0, 6)),
  ];
}