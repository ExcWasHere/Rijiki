import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class TokenStorage {
  TokenStorage({FlutterSecureStorage? storage})
      : _storage = storage ?? const FlutterSecureStorage();

  static const String _accessKey = 'access_token';
  static const String _refreshKey = 'refresh_token';
  static const String _onboardingKey = 'onboarding_completed';
  static const String _landingKey = 'landing_seen';
  static const String _redemptionSeenPrefix = 'redemption_rejection_seen_';

  final FlutterSecureStorage _storage;

  Future<String?> readAccessToken() => _storage.read(key: _accessKey);

  Future<String?> readRefreshToken() => _storage.read(key: _refreshKey);

  Future<bool> hasSession() async => (await readRefreshToken()) != null;

  Future<bool> isOnboardingCompleted() async =>
      (await _storage.read(key: _onboardingKey)) == 'true';

  Future<void> setOnboardingCompleted(bool completed) =>
      _storage.write(key: _onboardingKey, value: completed.toString());

  Future<bool> isLandingSeen() async =>
      (await _storage.read(key: _landingKey)) == 'true';

  Future<void> setLandingSeen(bool seen) =>
      _storage.write(key: _landingKey, value: seen.toString());

  /// Waktu penolakan penukaran poin terakhir yang sudah ditampilkan ke
  /// customer ini. null = belum pernah dicatat di perangkat ini. Kuncinya per
  /// user dan sengaja tidak dihapus oleh [clear], jadi logout tidak membuat
  /// penolakan lama muncul lagi.
  Future<DateTime?> readRedemptionSeenAt(String userId) async {
    final raw = await _storage.read(key: '$_redemptionSeenPrefix$userId');
    final millis = int.tryParse(raw ?? '');
    if (millis == null) return null;
    return DateTime.fromMillisecondsSinceEpoch(millis, isUtc: true);
  }

  Future<void> writeRedemptionSeenAt(String userId, DateTime value) {
    return _storage.write(
      key: '$_redemptionSeenPrefix$userId',
      value: value.toUtc().millisecondsSinceEpoch.toString(),
    );
  }

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
