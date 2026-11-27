import 'package:flutter/foundation.dart';

abstract final class AppConstants {
  static const Duration splashStageDuration = Duration(milliseconds: 1500);
  static const Duration splashMinDuration = Duration(milliseconds: 2800);

  /// Fitur scan sepatu masih memakai model tiruan (model asli belum selesai),
  /// jadi hanya diaktifkan di build debug. Di build release tombol, tab, dan
  /// route-nya disembunyikan supaya tidak ada hasil palsu yang tampil ke
  /// pengguna sungguhan.
  static const bool scanEnabled = !kReleaseMode;

  static const String apiBaseUrl = String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: 'http://10.0.2.2:8787',
  );
  static const Duration requestTimeout = Duration(seconds: 15);
  static const String googleServerClientId = String.fromEnvironment(
    'GOOGLE_SERVER_CLIENT_ID',
  );

  static const int passwordMinLength = 8;
  static const int otpLength = 6;
  static const Duration otpResendCooldown = Duration(seconds: 60);
}
