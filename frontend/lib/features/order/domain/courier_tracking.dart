import 'package:latlong2/latlong.dart';

class CourierTracking {
  const CourierTracking({
    required this.position,
    required this.heading,
    required this.destination,
    required this.route,
    required this.etaMinutes,
    this.queuePosition = 1,
    this.queueSize = 1,
    this.recordedAt,
    this.hasLivePosition = true,
    this.isEstimate = false,
  });

  final LatLng position;
  final double heading;
  final LatLng destination;
  final List<LatLng> route;
  final int etaMinutes;
  final int queuePosition;
  final int queueSize;
  final DateTime? recordedAt;
  final bool hasLivePosition;
  final bool isEstimate;

  bool get isWaitingForOtherOrder => queuePosition > 1;

  CourierTracking copyWith({LatLng? position}) {
    return CourierTracking(
      position: position ?? this.position,
      heading: heading,
      destination: destination,
      route: route,
      etaMinutes: etaMinutes,
      queuePosition: queuePosition,
      queueSize: queueSize,
      recordedAt: recordedAt,
      hasLivePosition: hasLivePosition,
      isEstimate: isEstimate,
    );
  }
}
