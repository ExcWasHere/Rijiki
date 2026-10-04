abstract final class AppConstants {
  static const Duration splashStageDuration = Duration(milliseconds: 1500);
  static const Duration splashMinDuration = Duration(milliseconds: 2800);

  static const String apiBaseUrl = String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: 'http://10.0.2.2:8787',
  );
  static const bool useMockAuth = bool.fromEnvironment('USE_MOCK_AUTH');
  static const Duration requestTimeout = Duration(seconds: 15);

  // Google Sign-In: isi dengan **Web client ID** (bukan Android client ID).
  static const String googleServerClientId = String.fromEnvironment(
    'GOOGLE_SERVER_CLIENT_ID',
  );

  static const int passwordMinLength = 8;
  static const int otpLength = 6;
  static const Duration otpResendCooldown = Duration(seconds: 60);
}
