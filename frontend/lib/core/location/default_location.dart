import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:latlong2/latlong.dart';

/// Alamat default customer beserta koordinatnya (customer_profiles.default_address,
/// default_lat, default_lng).
@immutable
class DefaultLocation {
  const DefaultLocation({required this.address, this.point});

  final String address;
  final LatLng? point;
}

class DefaultLocationNotifier extends Notifier<DefaultLocation?> {
  @override
  DefaultLocation? build() => null;

  void set(DefaultLocation value) => state = value;

  void clear() => state = null;
}

// TODO(backend): ganti dengan data profil dari API (customer_profiles) dan
// kosongkan saat logout.
final defaultLocationProvider =
    NotifierProvider<DefaultLocationNotifier, DefaultLocation?>(
      DefaultLocationNotifier.new,
    );
