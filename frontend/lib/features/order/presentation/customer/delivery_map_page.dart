import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:rijiki/core/enums/order_status.dart';
import 'package:rijiki/core/theme/app_colors.dart';
import 'package:rijiki/core/theme/app_spacing.dart';
import 'package:rijiki/features/order/domain/courier_tracking.dart';
import 'package:rijiki/features/order/domain/customer_order.dart';
import 'package:rijiki/features/order/presentation/controllers/courier_tracking_controller.dart';
import 'package:rijiki/features/order/presentation/controllers/order_detail_controller.dart';
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
  static const _sheetHeight = 230.0;

  GoogleMapController? _map;
  bool _follow = true;
  bool _fitted = false;

  @override
  void dispose() {
    _map?.dispose();
    super.dispose();
  }

  Future<void> _onUpdate(CourierTracking t) async {
    final map = _map;
    if (map == null) return;
    if (!_fitted) {
      _fitted = true;
      await map.animateCamera(
        CameraUpdate.newLatLngBounds(_boundsOf(t.position, t.destination), 90),
      );
    } else if (_follow) {
      await map.animateCamera(CameraUpdate.newLatLng(t.position));
    }
  }

  LatLngBounds _boundsOf(LatLng a, LatLng b) => LatLngBounds(
        southwest: LatLng(
          a.latitude < b.latitude ? a.latitude : b.latitude,
          a.longitude < b.longitude ? a.longitude : b.longitude,
        ),
        northeast: LatLng(
          a.latitude > b.latitude ? a.latitude : b.latitude,
          a.longitude > b.longitude ? a.longitude : b.longitude,
        ),
      );

  Future<void> _recenter(CourierTracking t) async {
    setState(() => _follow = true);
    await _map?.animateCamera(
      CameraUpdate.newLatLngBounds(_boundsOf(t.position, t.destination), 90),
    );
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
      data: (t) => Stack(
        children: [
          Positioned.fill(
            child: GoogleMap(
              initialCameraPosition: CameraPosition(target: t.position, zoom: 15),
              padding: const EdgeInsets.only(bottom: _sheetHeight),
              onMapCreated: (c) {
                _map = c;
                _onUpdate(t);
              },
              onCameraMoveStarted: () {
              },
              onCameraMove: (_) {},
              myLocationButtonEnabled: false,
              zoomControlsEnabled: false,
              mapToolbarEnabled: false,
              compassEnabled: false,
              polylines: {
                Polyline(
                  polylineId: const PolylineId('route'),
                  points: t.route,
                  color: AppColors.primaryDark,
                  width: 5,
                  startCap: Cap.roundCap,
                  endCap: Cap.roundCap,
                  jointType: JointType.round,
                ),
              },
              markers: {
                Marker(
                  markerId: const MarkerId('destination'),
                  position: t.destination,
                  icon: BitmapDescriptor.defaultMarkerWithHue(
                    BitmapDescriptor.hueOrange,
                  ),
                ),
                Marker(
                  markerId: const MarkerId('courier'),
                  position: t.position,
                  rotation: t.heading,
                  flat: true,
                  anchor: const Offset(0.5, 0.5),
                  zIndexInt: 2,
                  // TODO: ganti dengan ikon motor kustom, mis.
                  // await BitmapDescriptor.asset(
                  //   const ImageConfiguration(size: Size(48, 48)),
                  //   'assets/images/courier_marker.png',
                  // )
                  icon: BitmapDescriptor.defaultMarkerWithHue(
                    BitmapDescriptor.hueAzure,
                  ),
                ),
              },
            ),
          ),
          Positioned.fill(
            bottom: _sheetHeight,
            child: Listener(
              behavior: HitTestBehavior.translucent,
              onPointerMove: (_) {
                if (_follow) setState(() => _follow = false);
              },
            ),
          ),
          Positioned(
            right: AppSpacing.lg,
            bottom: _sheetHeight + AppSpacing.md,
            child: FloatingActionButton.small(
              heroTag: 'recenter',
              backgroundColor: Colors.white,
              onPressed: () => _recenter(t),
              child: Icon(
                Icons.my_location_rounded,
                color: _follow ? AppColors.rijikiBlue : AppColors.onSurfaceVariant,
              ),
            ),
          ),
          Positioned(
            left: AppSpacing.lg,
            right: AppSpacing.lg,
            bottom: AppSpacing.lg,
            child: _CourierCard(order: widget.order, tracking: t),
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