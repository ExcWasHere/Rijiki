import 'dart:async';
import 'dart:io' show Platform;

import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:rijiki/features/notifications/domain/notification_repository.dart';

/// Penanganan pesan saat aplikasi di latar belakang wajib top-level.
@pragma('vm:entry-point')
Future<void> _onBackgroundMessage(RemoteMessage message) async {}

/// Pendaftaran token FCM perangkat ke backend dan penerusan pesan masuk ke
/// inbox aplikasi (PRD 29.12). Push hanya pelengkap: bila Firebase belum
/// dikonfigurasi, semua langkah dilewati tanpa mengganggu aplikasi.
class PushService {
  PushService({required this.repository});

  final NotificationRepository repository;

  bool _initialized = false;
  StreamSubscription<RemoteMessage>? _foregroundSub;
  StreamSubscription<String>? _tokenSub;
  String? _token;
  void Function()? _onMessage;

  /// Mendaftarkan perangkat milik pengguna yang sedang login.
  /// [onMessage] dipanggil saat push masuk ketika aplikasi sedang terbuka.
  Future<void> start({void Function()? onMessage}) async {
    _onMessage = onMessage;
    if (!await _ensureInitialized()) return;

    final messaging = FirebaseMessaging.instance;
    try {
      final settings = await messaging.requestPermission();
      if (settings.authorizationStatus == AuthorizationStatus.denied) return;

      _foregroundSub ??= FirebaseMessaging.onMessage.listen((message) {
        _onMessage?.call();
      });

      // getToken/onTokenRefresh masih dipakai karena backend mengirim lewat
      // `message.token` (FCM registration token). API pengganti `register()` +
      // `onRegistered` memberi Firebase Installation ID, bukan token FCM.
      // ignore: deprecated_member_use
      _tokenSub ??= messaging.onTokenRefresh.listen((token) {
        _token = token;
        _register(token);
      });

      // ignore: deprecated_member_use
      final token = await messaging.getToken();
      if (token != null) {
        _token = token;
        await _register(token);
      }
    } catch (error) {
      debugPrint('[PushService] gagal mendaftarkan perangkat: $error');
    }
  }

  /// Melepas token saat keluar agar perangkat tidak lagi menerima notifikasi.
  Future<void> stop() async {
    await _foregroundSub?.cancel();
    await _tokenSub?.cancel();
    _foregroundSub = null;
    _tokenSub = null;

    final token = _token;
    _token = null;
    if (token == null) return;

    try {
      await repository.unregisterDevice(token);
    } catch (error) {
      debugPrint('[PushService] gagal melepas token: $error');
    }
  }

  Future<bool> _ensureInitialized() async {
    if (_initialized) return true;
    try {
      // Android/iOS membaca konfigurasi native (google-services.json /
      // GoogleService-Info.plist); Flutter tidak mengirim opsi apa pun.
      await Firebase.initializeApp();
      FirebaseMessaging.onBackgroundMessage(_onBackgroundMessage);
      _initialized = true;
      return true;
    } catch (error) {
      debugPrint(
        '[PushService] Firebase belum dikonfigurasi, push dilewati: $error',
      );
      return false;
    }
  }

  Future<void> _register(String token) async {
    try {
      await repository.registerDevice(token: token, platform: _platform);
    } catch (error) {
      debugPrint('[PushService] gagal menyimpan token: $error');
    }
  }

  String get _platform => Platform.isIOS ? 'ios' : 'android';
}
