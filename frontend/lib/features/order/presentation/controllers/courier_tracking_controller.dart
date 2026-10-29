import 'dart:math' as math;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:latlong2/latlong.dart';
import 'package:rijiki/app/providers.dart';
import 'package:rijiki/core/constants/app_constants.dart';
import 'package:rijiki/core/error/failure.dart';
import 'package:rijiki/features/order/domain/courier_tracking.dart';

const Duration courierPollInterval = Duration(seconds: 10);
final courierTrackingProvider = StreamProvider.autoDispose
    .family<CourierTracking, String>((ref, orderId) {
      if (AppConstants.useMockOrders) return _simulate();
      return _poll(ref, orderId);
    });

Stream<CourierTracking> _poll(Ref ref, String orderId) async* {
  final repo = ref.read(courierTrackingRepositoryProvider);
  var hasData = false;

  while (true) {
    try {
      final tracking = await repo.fetch(orderId);
      if (tracking == null) {
        throw const Failure(
          FailureType.conflict,
          'Pengantaran sudah selesai atau belum dimulai.',
        );
      }
      hasData = true;
      yield tracking;
    } on Failure catch (e) {
      final transient =
          e.type == FailureType.network || e.type == FailureType.server;
      if (!hasData || !transient) rethrow;
    }
    await Future<void>.delayed(courierPollInterval);
  }
}

Stream<CourierTracking> _simulate() async* {
  const corners = [
    LatLng(-7.9434, 112.6139),
    LatLng(-7.9434, 112.6190),
    LatLng(-7.9475, 112.6190),
    LatLng(-7.9475, 112.6245),
    LatLng(-7.9520, 112.6245),
  ];

  final route = <LatLng>[];
  for (var i = 0; i < corners.length - 1; i++) {
    for (var s = 0; s < 20; s++) {
      final t = s / 20;
      route.add(
        LatLng(
          corners[i].latitude +
              (corners[i + 1].latitude - corners[i].latitude) * t,
          corners[i].longitude +
              (corners[i + 1].longitude - corners[i].longitude) * t,
        ),
      );
    }
  }
  route.add(corners.last);

  for (var i = 4; i < route.length; i++) {
    final next = route[math.min(i + 1, route.length - 1)];
    yield CourierTracking(
      position: route[i],
      heading: _bearing(route[i], next),
      destination: corners.last,
      route: route,
      etaMinutes: math.max(1, ((route.length - i) / 6).ceil()),
    );
    await Future<void>.delayed(const Duration(seconds: 1));
  }
}

double _bearing(LatLng a, LatLng b) {
  final dLng = (b.longitude - a.longitude) * math.pi / 180;
  final lat1 = a.latitude * math.pi / 180;
  final lat2 = b.latitude * math.pi / 180;
  final y = math.sin(dLng) * math.cos(lat2);
  final x =
      math.cos(lat1) * math.sin(lat2) -
      math.sin(lat1) * math.cos(lat2) * math.cos(dLng);
  return (math.atan2(y, x) * 180 / math.pi + 360) % 360;
}
