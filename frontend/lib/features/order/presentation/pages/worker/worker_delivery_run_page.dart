import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:rijiki/app/router/route_paths.dart';
import 'package:rijiki/core/enums/order_status.dart';
import 'package:rijiki/core/error/failure.dart';
import 'package:rijiki/core/location/location_service.dart';
import 'package:rijiki/core/map/map_config.dart';
import 'package:rijiki/core/theme/app_colors.dart';
import 'package:rijiki/core/theme/app_spacing.dart';
import 'package:rijiki/features/order/domain/courier_tracking.dart';
import 'package:rijiki/features/order/domain/customer_order.dart';
import 'package:rijiki/features/order/domain/staff_order_repository.dart';
import 'package:rijiki/features/order/presentation/controllers/courier_tracking_controller.dart';
import 'package:rijiki/features/order/presentation/controllers/courier_tracking_sender.dart';
import 'package:rijiki/features/order/presentation/controllers/staff_order_controller.dart';
import 'package:rijiki/features/order/presentation/widgets/courier_map_layers.dart';
import 'package:rijiki/shared/widgets/app_card.dart';
import 'package:rijiki/shared/widgets/empty_state.dart';
import 'package:rijiki/shared/widgets/error_state.dart';
import 'package:rijiki/shared/widgets/loading_skeleton.dart';

DateTime _enteredDelivery(CustomerOrder order) {
  DateTime? latest;
  for (final entry in order.statusHistory) {
    if (entry.status != OrderStatus.delivery) continue;
    if (latest == null || entry.changedAt.isAfter(latest)) {
      latest = entry.changedAt;
    }
  }
  return latest ?? order.createdAt;
}

List<CustomerOrder> deliveryRunOf(List<CustomerOrder> orders) {
  final run = [
    for (final order in orders)
      if (order.status == OrderStatus.delivery && order.assignedToMe) order,
  ];
  run.sort((a, b) {
    final byTime = _enteredDelivery(a).compareTo(_enteredDelivery(b));
    return byTime != 0 ? byTime : a.id.compareTo(b.id);
  });
  return run;
}

class WorkerDeliveryRunPage extends ConsumerStatefulWidget {
  const WorkerDeliveryRunPage({super.key});

  @override
  ConsumerState<WorkerDeliveryRunPage> createState() =>
      _WorkerDeliveryRunPageState();
}

class _WorkerDeliveryRunPageState extends ConsumerState<WorkerDeliveryRunPage> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) ref.read(courierTrackingSenderProvider.notifier).sync();
    });
  }

  @override
  Widget build(BuildContext context) {
    final orders = ref.watch(staffOrdersProvider(StaffOrderList.primary));

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(title: const Text('Peta pengantaran')),
      body: orders.when(
        skipLoadingOnReload: true,
        loading: () => const Padding(
          padding: EdgeInsets.all(AppSpacing.lg),
          child: LoadingSkeleton(height: 420),
        ),
        error: (error, _) => Center(
          child: ErrorState(
            message: error is Failure
                ? error.message
                : 'Pengantaran gagal dimuat. Coba lagi ya.',
            onRetry: () =>
                ref.invalidate(staffOrdersProvider(StaffOrderList.primary)),
          ),
        ),
        data: (all) {
          final run = deliveryRunOf(all);
          if (run.isEmpty) {
            return Center(
              child: EmptyState(
                icon: Icons.two_wheeler_rounded,
                title: 'Tidak ada pengantaran aktif',
                message:
                    'Tekan "Mulai antar" pada order yang sudah selesai dicuci.',
                actionLabel: 'Ke daftar pesanan',
                onAction: () => context.go(RoutePaths.workerOrders),
              ),
            );
          }
          return _RunBody(run: run);
        },
      ),
    );
  }
}

class _RunBody extends ConsumerWidget {
  const _RunBody({required this.run});

  final List<CustomerOrder> run;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final current = run.first;
    final tracking = ref.watch(courierTrackingProvider(current.id));
    final sender = ref.watch(courierTrackingSenderProvider);
    final screenHeight = MediaQuery.sizeOf(context).height;

    return Column(
      children: [
        Expanded(
          child: tracking.when(
            skipLoadingOnReload: true,
            loading: () => const Padding(
              padding: EdgeInsets.all(AppSpacing.lg),
              child: LoadingSkeleton(height: 420),
            ),
            error: (error, _) => Center(
              child: ErrorState(
                message: error is Failure
                    ? error.message
                    : 'Peta gagal dimuat. Coba lagi ya.',
                onRetry: () =>
                    ref.invalidate(courierTrackingProvider(current.id)),
              ),
            ),
            data: (t) {
              final live = sender.latest;
              final shown = live != null ? t.copyWith(position: live) : t;
              return _RunMap(key: ValueKey(current.id), tracking: shown);
            },
          ),
        ),
        ConstrainedBox(
          constraints: BoxConstraints(maxHeight: screenHeight * 0.45),
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(AppSpacing.lg),
            child: SafeArea(
              top: false,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  _SenderStatus(state: sender),
                  const SizedBox(height: AppSpacing.md),
                  _CurrentStopCard(
                    order: current,
                    tracking: tracking.value,
                    onOpen: () => context.push(
                      RoutePaths.workerOrderDetailFor(current.id),
                    ),
                  ),
                  if (run.length > 1) ...[
                    const SizedBox(height: AppSpacing.md),
                    _QueueList(
                      orders: run.skip(1).toList(),
                      onOpen: (order) => context.push(
                        RoutePaths.workerOrderDetailFor(order.id),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _RunMap extends StatefulWidget {
  const _RunMap({super.key, required this.tracking});

  final CourierTracking tracking;

  @override
  State<_RunMap> createState() => _RunMapState();
}

class _RunMapState extends State<_RunMap> {
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

  @override
  void didUpdateWidget(covariant _RunMap oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (_ready &&
        _follow &&
        oldWidget.tracking.position != widget.tracking.position) {
      _controller.move(widget.tracking.position, _controller.camera.zoom);
    }
  }

  @override
  Widget build(BuildContext context) {
    final t = widget.tracking;

    return Stack(
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
                if (hasGesture && _follow) setState(() => _follow = false);
              },
            ),
            children: buildCourierMapLayers(t, routeWidth: 5),
          ),
        ),
        Positioned(
          right: AppSpacing.lg,
          bottom: AppSpacing.md,
          child: FloatingActionButton.small(
            heroTag: 'run-recenter',
            backgroundColor: Colors.white,
            onPressed: () {
              setState(() => _follow = true);
              _controller.fitCamera(_fitOf(t));
            },
            child: Icon(
              Icons.my_location_rounded,
              color: _follow ? AppColors.rijikiBlue : AppColors.onSurfaceVariant,
            ),
          ),
        ),
      ],
    );
  }
}

class _SenderStatus extends ConsumerWidget {
  const _SenderStatus({required this.state});

  final CourierSenderState state;

  static String _issueText(LocationIssue issue) => switch (issue) {
    LocationIssue.serviceDisabled =>
      'GPS perangkat mati. Nyalakan agar customer bisa melihat posisimu.',
    LocationIssue.denied =>
      'Izin lokasi belum diberikan. Customer belum bisa melihat posisimu.',
    LocationIssue.deniedForever =>
      'Izin lokasi ditolak permanen. Aktifkan lewat pengaturan aplikasi.',
    LocationIssue.unavailable =>
      'Lokasi belum bisa dibaca. Pastikan GPS aktif lalu coba lagi.',
  };

  static String _ago(DateTime at) {
    final seconds = DateTime.now().difference(at).inSeconds;
    if (seconds < 60) return '${seconds < 0 ? 0 : seconds} dtk lalu';
    return '${seconds ~/ 60} mnt lalu';
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final textTheme = Theme.of(context).textTheme;
    final issue = state.issue;

    if (issue != null) {
      final location = ref.read(locationServiceProvider);
      return Container(
        padding: const EdgeInsets.all(AppSpacing.md),
        decoration: BoxDecoration(
          color: AppColors.warning.withValues(alpha: 0.14),
          borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(_issueText(issue), style: textTheme.bodyMedium),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              children: [
                FilledButton(
                  onPressed: () => ref
                      .read(courierTrackingSenderProvider.notifier)
                      .retry(),
                  child: const Text('Aktifkan lagi'),
                ),
                if (issue == LocationIssue.deniedForever)
                  OutlinedButton(
                    onPressed: location.openAppSettings,
                    child: const Text('Buka pengaturan'),
                  ),
                if (issue == LocationIssue.serviceDisabled)
                  OutlinedButton(
                    onPressed: location.openLocationSettings,
                    child: const Text('Buka pengaturan GPS'),
                  ),
              ],
            ),
          ],
        ),
      );
    }

    final sentAt = state.lastSentAt;
    return Row(
      children: [
        Icon(
          state.running ? Icons.gps_fixed_rounded : Icons.gps_not_fixed_rounded,
          size: 18,
          color: state.running ? AppColors.success : AppColors.onSurfaceVariant,
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            state.running
                ? 'Lokasi dibagikan ke customer'
                      '${sentAt == null ? '' : ' · terkirim ${_ago(sentAt)}'}'
                : 'Menyiapkan pelacakan lokasi…',
            style: textTheme.bodySmall?.copyWith(
              color: AppColors.onSurfaceVariant,
            ),
          ),
        ),
      ],
    );
  }
}

class _CurrentStopCard extends StatelessWidget {
  const _CurrentStopCard({
    required this.order,
    required this.tracking,
    required this.onOpen,
  });

  final CustomerOrder order;
  final CourierTracking? tracking;
  final VoidCallback onOpen;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final muted = textTheme.bodySmall?.copyWith(
      color: AppColors.onSurfaceVariant,
    );
    final eta = tracking;

    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.flag_rounded, color: AppColors.rijikiOrange),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Tujuan sekarang · ${order.orderNumber}',
                  style: textTheme.titleSmall,
                ),
              ),
              if (eta != null && eta.hasLivePosition)
                Text('~${eta.etaMinutes} mnt', style: textTheme.titleSmall),
            ],
          ),
          const SizedBox(height: 10),
          Text(order.customerName ?? 'Customer', style: textTheme.bodyLarge),
          if ((order.customerPhone ?? '').isNotEmpty)
            Text(order.customerPhone!, style: muted),
          const SizedBox(height: 6),
          Text(order.deliveryAddress, style: textTheme.bodyMedium),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            child: FilledButton(
              onPressed: onOpen,
              child: const Text('Buka detail & selesaikan'),
            ),
          ),
        ],
      ),
    );
  }
}

class _QueueList extends StatelessWidget {
  const _QueueList({required this.orders, required this.onOpen});

  final List<CustomerOrder> orders;
  final ValueChanged<CustomerOrder> onOpen;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Berikutnya', style: textTheme.titleSmall),
          const SizedBox(height: 2),
          Text(
            'Menunggu pesanan sebelumnya selesai.',
            style: textTheme.bodySmall?.copyWith(
              color: AppColors.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 8),
          for (var i = 0; i < orders.length; i++)
            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: CircleAvatar(
                radius: 16,
                backgroundColor: AppColors.primary.withValues(alpha: 0.2),
                foregroundColor: AppColors.primaryDark,
                child: Text('${i + 2}'),
              ),
              title: Text(
                '${orders[i].orderNumber} · ${orders[i].customerName ?? 'Customer'}',
              ),
              subtitle: Text(
                orders[i].deliveryAddress,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              trailing: const Icon(Icons.chevron_right_rounded),
              onTap: () => onOpen(orders[i]),
            ),
        ],
      ),
    );
  }
}
