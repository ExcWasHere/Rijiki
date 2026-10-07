import 'package:flutter/material.dart';
import 'package:rijiki/core/theme/app_colors.dart';

class CyanCircleDecoration extends StatelessWidget {
  final double width;
  final double height;
  final Color color;

  const CyanCircleDecoration({
    super.key,
    this.width = 150,
    this.height = 150,
    this.color = const Color(0xFFAEE1E1),
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: color,
      ),
    );
  }
}

class LeftOrangeBlobDecoration extends StatelessWidget {
  final double height;
  final double width;

  const LeftOrangeBlobDecoration({
    super.key,
    this.height = 260,
    this.width = 160,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: width,
      height: height,
      child: CustomPaint(
        painter: _OrangeBlobPainter(),
      ),
    );
  }
}

class _OrangeBlobPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = AppColors.rijikiOrange
      ..style = PaintingStyle.fill;

    final path = Path();
    path.moveTo(0, 0);
    path.cubicTo(
      size.width * 0.95, size.height * 0.2,
      size.width * 1.0, size.height * 0.65,
      size.width * 0.35, size.height * 0.95,
    );

    path.cubicTo(
      size.width * 0.1, size.height * 1.0,
      0, size.height * 0.92,
      0, size.height * 0.8,
    );

    path.close();
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
