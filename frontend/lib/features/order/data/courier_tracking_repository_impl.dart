import 'package:latlong2/latlong.dart';
import 'package:rijiki/core/constants/app_strings.dart';
import 'package:rijiki/core/error/app_exception.dart';
import 'package:rijiki/core/error/failure.dart';
import 'package:rijiki/core/map/map_config.dart';
import 'package:rijiki/core/network/api_client.dart';
import 'package:rijiki/core/network/api_endpoint.dart';
import 'package:rijiki/features/order/domain/courier_tracking.dart';
import 'package:rijiki/features/order/domain/courier_tracking_repository.dart';

class CourierTrackingRepositoryImpl implements CourierTrackingRepository {
  CourierTrackingRepositoryImpl({required this.api});

  final ApiClient api;

  @override
  Future<CourierTracking?> fetch(String orderId) async {
    try {
      final json = await api.get(ApiEndpoints.orderTracking(orderId), auth: true);
      return _fromJson(json);
    } on AppException catch (e) {
      throw _toFailure(e);
    }
  }

  @override
  Future<void> sendPoint({
    required String orderId,
    required LatLng point,
  }) async {
    try {
      await api.post(
        ApiEndpoints.orderTracking(orderId),
        auth: true,
        body: {'latitude': point.latitude, 'longitude': point.longitude},
      );
    } on AppException catch (e) {
      throw _toFailure(e);
    }
  }

  CourierTracking? _fromJson(Json json) {
    if (json['active'] != true) return null;

    final point = json['point'];
    final destination = json['destination'];
    final live = point is Map<String, dynamic>;

    final LatLng position = live
        ? LatLng(
            (point['latitude'] as num).toDouble(),
            (point['longitude'] as num).toDouble(),
          )
        : MapConfig.outlet;

    final LatLng target = destination is Map<String, dynamic>
        ? LatLng(
            (destination['latitude'] as num).toDouble(),
            (destination['longitude'] as num).toDouble(),
          )
        : position;

    final rawRoute = json['route'];
    final route = rawRoute is List
        ? [
            for (final p in rawRoute)
              if (p is List && p.length >= 2)
                LatLng((p[0] as num).toDouble(), (p[1] as num).toDouble()),
          ]
        : <LatLng>[position, target];

    return CourierTracking(
      position: position,
      heading: live ? ((point['heading'] as num?)?.toDouble() ?? 0) : 0,
      destination: target,
      route: route.length >= 2 ? route : <LatLng>[position, target],
      etaMinutes: (json['eta_minutes'] as num?)?.round() ?? 0,
      queuePosition: (json['queue_position'] as num?)?.round() ?? 1,
      queueSize: (json['queue_size'] as num?)?.round() ?? 1,
      recordedAt: live
          ? DateTime.tryParse(point['recorded_at'] as String? ?? '')?.toLocal()
          : null,
      hasLivePosition: live,
      isEstimate: json['route_source'] != 'osrm',
    );
  }

  Failure _toFailure(AppException e) {
    if (e.isNetwork) {
      return Failure(FailureType.network, e.message, code: e.code);
    }
    switch (e.statusCode) {
      case 401:
        return Failure(FailureType.unauthorized, e.message, code: e.code);
      case 409:
        return Failure(FailureType.conflict, e.message, code: e.code);
      case 400:
      case 403:
      case 404:
        return Failure(FailureType.validation, e.message, code: e.code);
    }
    if ((e.statusCode ?? 0) >= 500) {
      return Failure(FailureType.server, e.message, code: e.code);
    }
    return Failure(
      FailureType.unknown,
      e.message.isEmpty ? AppStrings.errUnknown : e.message,
      code: e.code,
    );
  }
}
