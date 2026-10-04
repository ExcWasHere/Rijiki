import 'dart:math' as math;
import 'package:flutter/material.dart';

class GoogleLogo extends StatelessWidget {
  const GoogleLogo({super.key, this.size = 20});

  final double size;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size,
      height: size,
      child: const CustomPaint(painter: _GoogleLogoPainter()),
    );
  }
}

class _GoogleLogoPainter extends CustomPainter {
  const _GoogleLogoPainter();

  static const double _artWidth = 256;
  static const double _artHeight = 262;

  static final Path _blue = Path()
    ..moveTo(255.878, 133.451)
    ..cubicTo(255.878, 122.717, 255.007, 114.884, 253.122, 106.761)
    ..lineTo(130.55, 106.761)
    ..lineTo(130.55, 155.209)
    ..lineTo(202.497, 155.209)
    ..cubicTo(201.047, 167.249, 193.214, 185.381, 175.807, 197.565)
    ..lineTo(175.563, 199.187)
    ..lineTo(214.318, 229.21)
    ..lineTo(217.003, 229.478)
    ..cubicTo(241.662, 206.704, 255.878, 173.196, 255.878, 133.451);

  static final Path _green = Path()
    ..moveTo(130.55, 261.1)
    ..cubicTo(165.798, 261.1, 195.389, 249.495, 217.003, 229.478)
    ..lineTo(175.807, 197.565)
    ..cubicTo(164.783, 205.253, 149.987, 210.62, 130.55, 210.62)
    ..cubicTo(96.027, 210.62, 66.726, 187.847, 56.281, 156.37)
    ..lineTo(54.75, 156.5)
    ..lineTo(14.452, 187.687)
    ..lineTo(13.925, 189.152)
    ..cubicTo(35.393, 231.798, 79.49, 261.1, 130.55, 261.1);

  static final Path _yellow = Path()
    ..moveTo(56.281, 156.37)
    ..cubicTo(53.525, 148.247, 51.93, 139.543, 51.93, 130.55)
    ..cubicTo(51.93, 121.556, 53.525, 112.853, 56.136, 104.73)
    ..lineTo(56.063, 103)
    ..lineTo(15.26, 71.312)
    ..lineTo(13.925, 71.947)
    ..cubicTo(5.077, 89.644, 0, 109.517, 0, 130.55)
    ..cubicTo(0, 151.583, 5.077, 171.455, 13.925, 189.152)
    ..close();

  static final Path _red = Path()
    ..moveTo(130.55, 50.479)
    ..cubicTo(155.064, 50.479, 171.6, 61.068, 181.029, 69.917)
    ..lineTo(217.873, 33.943)
    ..cubicTo(195.245, 12.91, 165.798, 0, 130.55, 0)
    ..cubicTo(79.49, 0, 35.393, 29.301, 13.925, 71.947)
    ..lineTo(56.136, 104.73)
    ..cubicTo(66.726, 73.253, 96.027, 50.479, 130.55, 50.479);

  static final List<(Path, Color)> _layers = [
    (_blue, Color(0xFF4285F4)),
    (_green, Color(0xFF34A853)),
    (_yellow, Color(0xFFFBBC05)),
    (_red, Color(0xFFEA4335)),
  ];

  @override
  void paint(Canvas canvas, Size size) {
    final scale = math.min(size.width / _artWidth, size.height / _artHeight);
    final dx = (size.width - _artWidth * scale) / 2;
    final dy = (size.height - _artHeight * scale) / 2;

    canvas
      ..save()
      ..translate(dx, dy)
      ..scale(scale);

    for (final (path, color) in _layers) {
      canvas.drawPath(
        path,
        Paint()
          ..color = color
          ..style = PaintingStyle.fill
          ..isAntiAlias = true,
      );
    }
    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
