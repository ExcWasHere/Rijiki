import 'package:latlong2/latlong.dart';

/// Konfigurasi peta (flutter_map + OpenStreetMap).
///
/// Server tile publik OpenStreetMap hanya layak untuk development, demo, dan
/// pengguna sedikit. Kalau nanti ramai, cukup ganti [tileUrlTemplate] (dan
/// [maxNativeZoom]) ke provider tile lain; widget peta tidak perlu diubah.
abstract final class MapConfig {
  static const String tileUrlTemplate =
      'https://tile.openstreetmap.org/{z}/{x}/{y}.png';

  /// WAJIB diganti dengan applicationId asli aplikasi (lihat
  /// android/app/build.gradle*). Jangan pakai 'com.example.app': permintaan
  /// dengan nilai itu diblokir oleh server tile OpenStreetMap.
  static const String userAgentPackageName = 'GANTI.DENGAN.APPLICATION.ID';

  static const int maxNativeZoom = 19;
  static const double maxZoom = 19;

  /// Titik outlet: Gedung Teknik Mesin Politeknik Negeri Malang
  /// (PRD Open Questions #38). Dipakai sebagai pusat peta bawaan.
  static const LatLng outlet = LatLng(-7.9434265, 112.6138782);
}
