import 'package:google_maps_flutter/google_maps_flutter.dart';

class CourierTracking {
  const CourierTracking({
    required this.position,
    required this.heading,
    required this.destination,
    required this.route,
    required this.etaMinutes,
  });

  final LatLng position;
  final double heading;
  final LatLng destination;
  final List<LatLng> route;
  final int etaMinutes;
}