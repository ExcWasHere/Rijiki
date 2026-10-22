import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:latlong2/latlong.dart';
import 'package:rijiki/core/session/session_provider.dart';

@immutable
class DefaultLocation {
  const DefaultLocation({required this.address, this.point});

  final String address;
  final LatLng? point;
}

class DefaultLocationNotifier extends Notifier<DefaultLocation?> {
  @override
  DefaultLocation? build() {
    final user = ref.watch(sessionProvider);
    final address = user?.defaultAddress?.trim();
    if (user == null || address == null || address.isEmpty) return null;

    final lat = user.defaultLat;
    final lng = user.defaultLng;
    return DefaultLocation(
      address: address,
      point: (lat != null && lng != null) ? LatLng(lat, lng) : null,
    );
  }

  void set(DefaultLocation value) => state = value;

  void clear() => state = null;
}

final defaultLocationProvider =
    NotifierProvider<DefaultLocationNotifier, DefaultLocation?>(
      DefaultLocationNotifier.new,
    );
