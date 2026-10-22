import 'package:latlong2/latlong.dart';

abstract final class ServiceArea {
  static const double minLat = -8.5;
  static const double maxLat = -7.7;
  static const double minLng = 112.25;
  static const double maxLng = 113.0;

  static const String outOfAreaMessage =
      'Lokasi kamu berada di luar area layanan Rijiki (Kota Malang, Kabupaten Malang, dan Kota Batu), maaf yah :(';

  static bool contains(LatLng point) {
    return point.latitude >= minLat &&
        point.latitude <= maxLat &&
        point.longitude >= minLng &&
        point.longitude <= maxLng;
  }
}
