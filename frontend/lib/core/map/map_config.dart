import 'package:latlong2/latlong.dart';
abstract final class MapConfig {
  static const String tileUrlTemplate =
      'https://tile.openstreetmap.org/{z}/{x}/{y}.png';
  static const String userAgentPackageName = 'com.id.rijiki';
  static const int maxNativeZoom = 19;
  static const double maxZoom = 19;
  static const LatLng outlet = LatLng(-7.9434265, 112.6138782);
}
