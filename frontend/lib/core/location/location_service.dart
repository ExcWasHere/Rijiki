import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geocoding/geocoding.dart' as geo;
import 'package:geolocator/geolocator.dart';
import 'package:latlong2/latlong.dart';

enum LocationIssue { serviceDisabled, denied, deniedForever, unavailable }

class LocationException implements Exception {
  const LocationException(this.issue);

  final LocationIssue issue;

  @override
  String toString() => 'LocationException($issue)';
}

class LocationService {
  LocationService({geo.Geocoding? geocoding})
    : _geocoding = geocoding ?? geo.Geocoding();

  final geo.Geocoding _geocoding;

  static final RegExp _plusCode = RegExp(
    r'^[23456789CFGHJMPQRVWX]{4,8}\+[23456789CFGHJMPQRVWX]{2,}',
  );

  Future<LatLng> currentPoint() async {
    if (!await Geolocator.isLocationServiceEnabled()) {
      throw const LocationException(LocationIssue.serviceDisabled);
    }

    var permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
    }
    if (permission == LocationPermission.deniedForever) {
      throw const LocationException(LocationIssue.deniedForever);
    }
    if (permission == LocationPermission.denied) {
      throw const LocationException(LocationIssue.denied);
    }

    try {
      final position = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
          timeLimit: Duration(seconds: 15),
        ),
      );
      return LatLng(position.latitude, position.longitude);
    } catch (_) {
      throw const LocationException(LocationIssue.unavailable);
    }
  }

  Future<String?> addressOf(LatLng point) async {
    try {
      final marks = await _geocoding.placemarkFromCoordinates(
        point.latitude,
        point.longitude,
      );
      if (marks.isEmpty) return null;

      bool hasStreet(geo.Placemark m) {
        final street = (m.street ?? m.thoroughfare ?? '').trim();
        return street.isNotEmpty && !_plusCode.hasMatch(street);
      }

      final mark = marks.firstWhere(hasStreet, orElse: () => marks.first);

      final parts = <String>[];
      void add(String? value) {
        final text = value?.trim();
        if (text == null || text.isEmpty || _plusCode.hasMatch(text)) return;
        if (parts.any((p) => p.toLowerCase() == text.toLowerCase())) return;
        parts.add(text);
      }

      add(mark.street ?? mark.thoroughfare);
      add(mark.subLocality);
      add(mark.locality);
      add(mark.subAdministrativeArea);
      add(mark.administrativeArea);
      add(mark.postalCode);

      return parts.isEmpty ? null : parts.join(', ');
    } catch (_) {
      return null;
    }
  }

  Future<LatLng?> pointOf(String address) async {
    try {
      final results = await _geocoding.locationFromAddress(address);
      if (results.isEmpty) return null;
      return LatLng(results.first.latitude, results.first.longitude);
    } catch (_) {
      return null;
    }
  }

  Future<void> openAppSettings() async {
    await Geolocator.openAppSettings();
  }

  Future<void> openLocationSettings() async {
    await Geolocator.openLocationSettings();
  }
}

final locationServiceProvider = Provider<LocationService>(
  (ref) => LocationService(),
);