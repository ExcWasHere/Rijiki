import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:rijiki/core/enums/order_status.dart';
import 'package:rijiki/core/theme/app_colors.dart';
import 'package:rijiki/core/theme/app_spacing.dart';
import 'package:rijiki/features/order/domain/customer_order.dart';
import 'package:rijiki/features/order/presentation/controllers/order_detail_controller.dart';
import 'package:rijiki/shared/widgets/app_card.dart';
import 'package:rijiki/shared/widgets/empty_state.dart';
import 'package:rijiki/shared/widgets/error_state.dart';
import 'package:rijiki/shared/widgets/loading_skeleton.dart';

// TODO(backend): ganti dengan google_maps_flutter dan titik terbaru dari
// GET /api/orders/:id/tracking (PRD bagian 11).
class DeliveryMapPage extends ConsumerWidget {
  const DeliveryMapPage({super.key, required this.orderId});

  final String orderId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final order = ref.watch(orderDetailProvider(orderId));

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(title: const Text('Posisi kurir')),
      body: order.when(
        loading: () => const Padding(
          padding: EdgeInsets.all(AppSpacing.lg),
          child: LoadingSkeleton(height: 420),
        ),
        error: (_, _) => Center(
          child: ErrorState(
            message: 'Data order gagal dimuat. Coba lagi ya.',
            onRetry: () => ref.invalidate(orderDetailProvider(orderId)),
          ),
        ),
        data: (data) => data.status == OrderStatus.delivery
            ? _MapBody(order: data)
            : const Center(
                child: EmptyState(
                  icon: Icons.map_outlined,
                  title: 'Peta belum tersedia',
                  message:
                      'Posisi kurir hanya bisa dilihat saat sepatumu sedang diantar.',
                ),
              ),
      ),
    );
  }
}

class _MapBody extends StatefulWidget {
  const _MapBody({required this.order});

  final CustomerOrder order;

  @override
  State<_MapBody> createState() => _MapBodyState();
}

class _MapBodyState extends State<_MapBody>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(seconds: 8),
  )..forward();

  late final Animation<double> _progress = Tween<double>(
    begin: 0.2,
    end: 0.7,
  ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeInOut));

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final order = widget.order;

    return Stack(
      children: [
        Positioned.fill(
          child: AnimatedBuilder(
            animation: _controller,
            builder: (context, _) => CustomPaint(
              painter: _MapPainter(
                progress: _progress.value,
                pulse: (_controller.value * 4) % 1,
              ),
            ),
          ),
        ),
        Positioned(
          top: AppSpacing.md,
          left: AppSpacing.lg,
          right: AppSpacing.lg,
          child: Align(
            alignment: Alignment.topCenter,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: AppColors.onSurface.withValues(alpha: 0.85),
                borderRadius: BorderRadius.circular(999),
              ),
              child: Text(
                'Pratinjau tampilan · peta langsung menyusul',
                style: textTheme.labelMedium?.copyWith(color: Colors.white),
              ),
            ),
          ),
        ),
        Positioned(
          left: AppSpacing.lg,
          right: AppSpacing.lg,
          bottom: AppSpacing.lg,
          child: AppCard(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: AppColors.primary.withValues(alpha: 0.3),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.two_wheeler_rounded,
                        color: AppColors.primaryDark,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            order.workerName ?? 'Kurir Rijiki',
                            style: textTheme.titleSmall,
                          ),
                          Text(
                            'Sedang mengantar · ${order.orderNumber}',
                            style: textTheme.bodySmall?.copyWith(
                              color: AppColors.onSurfaceVariant,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                const Divider(),
                const SizedBox(height: 12),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Icon(
                      Icons.location_on_rounded,
                      size: 18,
                      color: AppColors.rijikiOrange,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Tujuan pengantaran',
                            style: textTheme.bodySmall?.copyWith(
                              color: AppColors.onSurfaceVariant,
                            ),
                          ),
                          Text(
                            order.deliveryAddress,
                            style: textTheme.bodyMedium,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _MapPainter extends CustomPainter {
  const _MapPainter({required this.progress, required this.pulse});
  final double progress;
  final double pulse;

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;

    canvas.drawRect(
      Offset.zero & size,
      Paint()..color = const Color(0xFFEAF1EE),
    );

    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(w * 0.58, h * 0.06, w * 0.34, h * 0.16),
        const Radius.circular(18),
      ),
      Paint()..color = const Color(0xFFCFE6CC),
    );
    final river = Path()
      ..moveTo(-10, h * 0.12)
      ..quadraticBezierTo(w * 0.25, h * 0.2, w * 0.4, h * 0.08)
      ..quadraticBezierTo(w * 0.5, 0, w * 0.55, -10);
    canvas.drawPath(
      river,
      Paint()
        ..color = const Color(0xFFBFDDF0)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 18
        ..strokeCap = StrokeCap.round,
    );

    final road = Paint()
      ..color = Colors.white
      ..strokeWidth = 12
      ..strokeCap = StrokeCap.round;
    for (final fx in [0.15, 0.5, 0.82]) {
      canvas.drawLine(Offset(w * fx, 0), Offset(w * fx, h), road);
    }
    for (final fy in [0.3, 0.55, 0.82]) {
      canvas.drawLine(Offset(0, h * fy), Offset(w, h * fy), road);
    }

    final start = Offset(w * 0.15, h * 0.82);
    final route = Path()
      ..moveTo(start.dx, start.dy)
      ..lineTo(w * 0.15, h * 0.55)
      ..lineTo(w * 0.5, h * 0.55)
      ..lineTo(w * 0.5, h * 0.3)
      ..lineTo(w * 0.82, h * 0.3);
    canvas.drawPath(
      route,
      Paint()
        ..color = AppColors.primaryDark
        ..style = PaintingStyle.stroke
        ..strokeWidth = 6
        ..strokeCap = StrokeCap.round
        ..strokeJoin = StrokeJoin.round,
    );

    final destination = Offset(w * 0.82, h * 0.3);
    canvas.drawCircle(destination, 13, Paint()..color = Colors.white);
    canvas.drawCircle(destination, 9, Paint()..color = AppColors.rijikiOrange);
    final metric = route.computeMetrics().first;
    final tangent = metric.getTangentForOffset(metric.length * progress);
    if (tangent != null) {
      final position = tangent.position;
      canvas.drawCircle(
        position,
        14 + 14 * pulse,
        Paint()
          ..color = AppColors.rijikiBlue.withValues(
            alpha: 0.35 * (1 - pulse),
          ),
      );
      canvas.drawCircle(position, 12, Paint()..color = Colors.white);
      canvas.drawCircle(position, 8, Paint()..color = AppColors.rijikiBlue);
      final heading = tangent.angle;
      canvas.drawCircle(
        position + Offset(math.cos(heading), math.sin(heading)) * 4,
        2,
        Paint()..color = Colors.white,
      );
    }
  }

  @override
  bool shouldRepaint(_MapPainter oldDelegate) =>
      oldDelegate.progress != progress || oldDelegate.pulse != pulse;
}
