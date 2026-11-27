import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geolocator/geolocator.dart';
import 'package:latlong2/latlong.dart';
import 'package:rijiki/app/providers.dart';
import 'package:rijiki/core/enums/order_status.dart';
import 'package:rijiki/core/enums/user_role.dart';
import 'package:rijiki/core/error/failure.dart';
import 'package:rijiki/core/location/location_service.dart';
import 'package:rijiki/core/session/session_provider.dart';
import 'package:rijiki/features/order/domain/customer_order.dart';
import 'package:rijiki/features/order/domain/staff_order_repository.dart';

class CourierSenderState {
  const CourierSenderState({
    this.running = false,
    this.orderIds = const {},
    this.latest,
    this.lastSentAt,
    this.issue,
  });

  final bool running;
  final Set<String> orderIds;
  final LatLng? latest;
  final DateTime? lastSentAt;
  final LocationIssue? issue;

  CourierSenderState copyWith({
    bool? running,
    Set<String>? orderIds,
    LatLng? latest,
    DateTime? lastSentAt,
    LocationIssue? issue,
    bool clearIssue = false,
    bool clearLatest = false,
  }) {
    return CourierSenderState(
      running: running ?? this.running,
      orderIds: orderIds ?? this.orderIds,
      latest: clearLatest ? null : (latest ?? this.latest),
      lastSentAt: lastSentAt ?? this.lastSentAt,
      issue: clearIssue ? null : (issue ?? this.issue),
    );
  }
}

class CourierTrackingSender extends Notifier<CourierSenderState> {
  static const Duration _minSendGap = Duration(seconds: 8);

  StreamSubscription<Position>? _subscription;
  DateTime? _lastPostAt;
  bool _syncing = false;

  @override
  CourierSenderState build() {
    ref.onDispose(() => unawaited(_subscription?.cancel()));
    ref.listen(sessionProvider, (previous, next) {
      if (next == null || next.role != UserRole.worker) {
        unawaited(_stop());
      } else if (previous?.id != next.id) {
        unawaited(sync());
      }
    }, fireImmediately: true);

    return const CourierSenderState();
  }

  Future<void> sync({bool promptPermission = false}) async {
    if (_syncing) return;
    _syncing = true;
    try {
      final user = ref.read(sessionProvider);
      if (user == null || user.role != UserRole.worker) {
        await _stop();
        return;
      }

      final List<CustomerOrder> orders;
      try {
        orders = await ref
            .read(staffOrderRepositoryProvider)
            .fetchOrders(StaffOrderList.primary);
      } catch (_) {
        return;
      }

      final ids = {
        for (final order in orders)
          if (order.status == OrderStatus.delivery && order.assignedToMe)
            order.id,
      };

      if (ids.isEmpty) {
        await _stop();
        return;
      }

      state = state.copyWith(orderIds: ids);
      if (_subscription == null) {
        await _start(promptPermission: promptPermission);
      }
    } finally {
      _syncing = false;
    }
  }

  Future<void> retry() => sync(promptPermission: true);

  Future<void> _start({required bool promptPermission}) async {
    final location = ref.read(locationServiceProvider);
    final issue = await location.trackingIssue(request: promptPermission);
    if (issue != null) {
      state = state.copyWith(running: false, issue: issue);
      return;
    }

    _subscription = location.trackingStream().listen(
      (position) => _onPosition(LatLng(position.latitude, position.longitude)),
      onError: (Object _) {
        unawaited(_handleStreamFailure());
      },
    );
    state = state.copyWith(running: true, clearIssue: true);
    try {
      _onPosition(await location.currentPoint());
    } catch (_) {
    }
  }

  Future<void> _handleStreamFailure() async {
    await _subscription?.cancel();
    _subscription = null;
    final issue = await ref.read(locationServiceProvider).trackingIssue();
    state = state.copyWith(
      running: false,
      issue: issue ?? LocationIssue.unavailable,
    );
  }

  void _onPosition(LatLng point) {
    state = state.copyWith(latest: point);

    final now = DateTime.now();
    final last = _lastPostAt;
    if (last != null && now.difference(last) < _minSendGap) return;
    _lastPostAt = now;

    unawaited(_push(point));
  }

  Future<void> _push(LatLng point) async {
    final repo = ref.read(courierTrackingRepositoryProvider);
    var staleOrder = false;
    var delivered = false;

    await Future.wait([
      for (final id in state.orderIds)
        () async {
          try {
            await repo.sendPoint(orderId: id, point: point);
            delivered = true;
          } on Failure catch (e) {
            if (e.type == FailureType.conflict ||
                e.type == FailureType.validation) {
              staleOrder = true;
            }
          }
        }(),
    ]);

    if (delivered) state = state.copyWith(lastSentAt: DateTime.now());
    if (staleOrder) unawaited(sync());
  }

  Future<void> _stop() async {
    await _subscription?.cancel();
    _subscription = null;
    _lastPostAt = null;
    state = const CourierSenderState();
  }
}

final courierTrackingSenderProvider =
    NotifierProvider<CourierTrackingSender, CourierSenderState>(
      CourierTrackingSender.new,
    );
