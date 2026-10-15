import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class TokenStorage {
  TokenStorage({FlutterSecureStorage? storage})
      : _storage = storage ?? const FlutterSecureStorage();

  static const String _accessKey = 'access_token';
  static const String _refreshKey = 'refresh_token';
  static const String _onboardingKey = 'onboarding_completed';
  static const String _landingKey = 'landing_seen'; // baru

  final FlutterSecureStorage _storage;

  Future<String?> readAccessToken() => _storage.read(key: _accessKey);

  Future<String?> readRefreshToken() => _storage.read(key: _refreshKey);

  Future<bool> hasSession() async => (await readRefreshToken()) != null;

  Future<bool> isOnboardingCompleted() async =>
      (await _storage.read(key: _onboardingKey)) == 'true';

  Future<void> setOnboardingCompleted(bool completed) =>
      _storage.write(key: _onboardingKey, value: completed.toString());

  // baru
  Future<bool> isLandingSeen() async =>
      (await _storage.read(key: _landingKey)) == 'true';

  // baru
  Future<void> setLandingSeen(bool seen) =>
      _storage.write(key: _landingKey, value: seen.toString());

  Future<void> save({
    required String accessToken,
    required String refreshToken,
  }) async {
    await _storage.write(key: _accessKey, value: accessToken);
    await _storage.write(key: _refreshKey, value: refreshToken);
  }

  Future<void> clear() async {
    await _storage.delete(key: _accessKey);
    await _storage.delete(key: _refreshKey);
  }
}