import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:rijiki/core/enums/order_status.dart';
import 'package:rijiki/core/map/map_config.dart';
import 'package:rijiki/core/theme/app_colors.dart';
import 'package:rijiki/core/theme/app_spacing.dart';
import 'package:rijiki/features/order/domain/courier_tracking.dart';
import 'package:rijiki/features/order/domain/customer_order.dart';
import 'package:rijiki/features/order/presentation/controllers/courier_tracking_controller.dart';
import 'package:rijiki/features/order/presentation/controllers/order_detail_controller.dart';
import 'package:rijiki/features/order/presentation/widgets/courier_map_layers.dart';
import 'package:rijiki/shared/widgets/app_card.dart';
import 'package:rijiki/shared/widgets/empty_state.dart';
import 'package:rijiki/shared/widgets/error_state.dart';
import 'package:rijiki/shared/widgets/loading_skeleton.dart';

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

class _MapBody extends ConsumerStatefulWidget {
  const _MapBody({required this.order});

  final CustomerOrder order;

  @override
  ConsumerState<_MapBody> createState() => _MapBodyState();
}

class _MapBodyState extends ConsumerState<_MapBody> {
  final MapController _controller = MapController();
  bool _ready = false;
  bool _follow = true;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  CameraFit _fitOf(CourierTracking t) => CameraFit.bounds(
    bounds: LatLngBounds.fromPoints([t.position, t.destination]),
    padding: const EdgeInsets.all(72),
    maxZoom: 17,
  );

  void _onUpdate(CourierTracking t) {
    if (!_ready || !_follow) return;
    _controller.move(t.position, _controller.camera.zoom);
  }

  void _recenter(CourierTracking t) {
    setState(() => _follow = true);
    _controller.fitCamera(_fitOf(t));
  }

  @override
  Widget build(BuildContext context) {
    final id = widget.order.id;
    final tracking = ref.watch(courierTrackingProvider(id));
    ref.listen(courierTrackingProvider(id), (_, next) {
      next.whenData(_onUpdate);
    });

    return tracking.when(
      loading: () => const Padding(
        padding: EdgeInsets.all(AppSpacing.lg),
        child: LoadingSkeleton(height: 420),
      ),
      error: (_, _) => Center(
        child: ErrorState(
          message: 'Posisi kurir gagal dimuat. Coba lagi ya.',
          onRetry: () => ref.invalidate(courierTrackingProvider(id)),
        ),
      ),
      data: (t) => Column(
        children: [
          Expanded(
            child: Stack(
              children: [
                Positioned.fill(
                  child: FlutterMap(
                    mapController: _controller,
                    options: MapOptions(
                      initialCameraFit: _fitOf(t),
                      maxZoom: MapConfig.maxZoom,
                      interactionOptions: const InteractionOptions(
                        flags: InteractiveFlag.all & ~InteractiveFlag.rotate,
                      ),
                      onMapReady: () => _ready = true,
                      onPositionChanged: (camera, hasGesture) {
                        if (hasGesture && _follow) {
                          setState(() => _follow = false);
                        }
                      },
                    ),
                    children: buildCourierMapLayers(t, routeWidth: 5),
                  ),
                ),
                Positioned(
                  right: AppSpacing.lg,
                  bottom: AppSpacing.md,
                  child: FloatingActionButton.small(
                    heroTag: 'recenter',
                    backgroundColor: Colors.white,
                    onPressed: () => _recenter(t),
                    child: Icon(
                      Icons.my_location_rounded,
                      color: _follow
                          ? AppColors.rijikiBlue
                          : AppColors.onSurfaceVariant,
                    ),
                  ),
                ),
              ],
            ),
          ),
          SafeArea(
            top: false,
            child: Padding(
              padding: const EdgeInsets.all(AppSpacing.lg),
              child: _CourierCard(order: widget.order, tracking: t),
            ),
          ),
        ],
      ),
    );
  }
}

class _CourierCard extends StatelessWidget {
  const _CourierCard({required this.order, required this.tracking});

  final CustomerOrder order;
  final CourierTracking tracking;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final arrived = tracking.position == tracking.destination;

    return AppCard(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            arrived ? 'Kurir sudah tiba' : 'Tiba sekitar ${tracking.etaMinutes} menit lagi',
            style: textTheme.titleMedium,
          ),
          const SizedBox(height: 12),
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
              // TODO(backend): sambungkan ke nomor kurir / chat.
              IconButton.filledTonal(
                onPressed: () {},
                icon: const Icon(Icons.chat_bubble_outline_rounded),
              ),
              const SizedBox(width: 4),
              IconButton.filledTonal(
                onPressed: () {},
                icon: const Icon(Icons.call_rounded),
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
                    Text(order.deliveryAddress, style: textTheme.bodyMedium),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
