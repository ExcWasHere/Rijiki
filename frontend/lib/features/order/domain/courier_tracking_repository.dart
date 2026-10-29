import 'package:latlong2/latlong.dart';
import 'package:rijiki/features/order/domain/courier_tracking.dart';

abstract interface class CourierTrackingRepository {
  Future<CourierTracking?> fetch(String orderId);
  Future<void> sendPoint({required String orderId, required LatLng point});
}
