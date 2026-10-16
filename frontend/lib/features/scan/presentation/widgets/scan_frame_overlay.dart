import 'package:flutter/material.dart';
import 'package:rijiki/core/theme/app_colors.dart';

class ScanFrameOverlay extends StatelessWidget {
  const ScanFrameOverlay({
    super.key,
    this.hint = 'Posisikan sepatu di dalam bingkai',
  });

  final String hint;

  static Rect frameRect(Size size) {
    final width = size.width * 0.86;
    final height = width * 0.78;
    final top = (size.height - height) * 0.38;
    return Rect.fromLTWH((size.width - width) / 2, top, width, height);
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final size = Size(constraints.maxWidth, constraints.maxHeight);
        final rect = frameRect(size);

        return Stack(
          children: [
            Positioned.fill(
              child: CustomPaint(painter: _FramePainter(rect)),
            ),
            Positioned(
              left: 24,
              right: 24,
              top: rect.bottom + 16,
              child: Text(
                hint,
                textAlign: TextAlign.center,
                style: Theme.of(
                  context,
                ).textTheme.bodyMedium?.copyWith(color: Colors.white),
              ),
            ),
          ],
        );
      },
    );
  }
}

class _FramePainter extends CustomPainter {
  const _FramePainter(this.rect);

  final Rect rect;

  static const double _radius = 20;
  static const double _bracket = 36;

  @override
  void paint(Canvas canvas, Size size) {
    final frame = RRect.fromRectAndRadius(rect, const Radius.circular(_radius));

    final dim = Path.combine(
      PathOperation.difference,
      Path()..addRect(Offset.zero & size),
      Path()..addRRect(frame),
    );
    canvas.drawPath(dim, Paint()..color = Colors.black.withValues(alpha: 0.5));

    const r = _radius;
    const l = _bracket;
    final brackets = Path()
      ..moveTo(rect.left, rect.top + l)
      ..lineTo(rect.left, rect.top + r)
      ..arcToPoint(
        Offset(rect.left + r, rect.top),
        radius: const Radius.circular(r),
      )
      ..lineTo(rect.left + l, rect.top)
      ..moveTo(rect.right - l, rect.top)
      ..lineTo(rect.right - r, rect.top)
      ..arcToPoint(
        Offset(rect.right, rect.top + r),
        radius: const Radius.circular(r),
      )
      ..lineTo(rect.right, rect.top + l)
      ..moveTo(rect.right, rect.bottom - l)
      ..lineTo(rect.right, rect.bottom - r)
      ..arcToPoint(
        Offset(rect.right - r, rect.bottom),
        radius: const Radius.circular(r),
      )
      ..lineTo(rect.right - l, rect.bottom)
      ..moveTo(rect.left + l, rect.bottom)
      ..lineTo(rect.left + r, rect.bottom)
      ..arcToPoint(
        Offset(rect.left, rect.bottom - r),
        radius: const Radius.circular(r),
      )
      ..lineTo(rect.left, rect.bottom - l);

    canvas.drawPath(
      brackets,
      Paint()
        ..color = AppColors.primary
        ..style = PaintingStyle.stroke
        ..strokeWidth = 4
        ..strokeCap = StrokeCap.round,
    );
  }

  @override
  bool shouldRepaint(_FramePainter oldDelegate) => oldDelegate.rect != rect;
}
