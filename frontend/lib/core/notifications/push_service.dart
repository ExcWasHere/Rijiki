import 'dart:async';
import 'dart:convert';
import 'dart:io' show Platform;
import 'dart:ui' show Color;

import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:rijiki/features/notifications/domain/notification_repository.dart';

/// Saat aplikasi di latar belakang atau tertutup, pesan FCM yang memuat
/// `notification` ditampilkan sistem Android memakai kanal & ikon dari
/// AndroidManifest; handler ini hanya wajib ada (top-level).
@pragma('vm:entry-point')
Future<void> _onBackgroundMessage(RemoteMessage message) async {}

/// Push notification (PRD 29.12): pendaftaran token FCM ke backend, banner
/// saat aplikasi terbuka, dan penerusan notifikasi yang diketuk ke aplikasi.
/// Push hanya pelengkap: bila Firebase belum dikonfigurasi, semua langkah
/// dilewati tanpa mengganggu aplikasi.
class PushService {
  PushService({required this.repository});

  final NotificationRepository repository;

  /// Sama dengan `ANDROID_CHANNEL_ID` di backend dan meta-data
  /// `default_notification_channel_id` di AndroidManifest.
  static const String channelId = 'rijiki_default';
  static const String _channelName = 'Notifikasi Rijiki';
  static const String _icon = 'ic_notification';
  static const Color _accent = Color(0xFF2EB4F2);

  static final FlutterLocalNotificationsPlugin _local =
      FlutterLocalNotificationsPlugin();
  static final StreamController<Map<String, dynamic>> _taps =
      StreamController<Map<String, dynamic>>.broadcast();
  static bool _firebaseReady = false;
  static bool _launchTaken = false;

  /// Dipanggil sekali di `main()` sebelum `runApp`, agar pesan yang membuka
  /// aplikasi dari keadaan tertutup tidak terlewat.
  static Future<void> initialize() async {
    try {
      // Android/iOS membaca konfigurasi native (google-services.json /
      // GoogleService-Info.plist); Flutter tidak mengirim opsi apa pun.
      await Firebase.initializeApp();
      FirebaseMessaging.onBackgroundMessage(_onBackgroundMessage);
      FirebaseMessaging.onMessageOpenedApp.listen(
        (message) => _taps.add(message.data),
      );
      _firebaseReady = true;
    } catch (error) {
      debugPrint(
        '[PushService] Firebase belum dikonfigurasi, push dilewati: $error',
      );
      return;
    }

    try {
      await _local.initialize(
        settings: const InitializationSettings(
          android: AndroidInitializationSettings(_icon),
          iOS: DarwinInitializationSettings(
            requestAlertPermission: false,
            requestBadgePermission: false,
            requestSoundPermission: false,
          ),
        ),
        onDidReceiveNotificationResponse: (response) {
          final data = _decode(response.payload);
          if (data != null) _taps.add(data);
        },
      );
      // Kanal penting (heads-up) dibuat lebih dulu supaya push dari sistem
      // saat aplikasi tertutup juga memakainya.
      await _local
          .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin
          >()
          ?.createNotificationChannel(
            const AndroidNotificationChannel(
              channelId,
              _channelName,
              description: 'Status order, pembayaran, dan poin',
              importance: Importance.high,
            ),
          );
    } catch (error) {
      debugPrint('[PushService] notifikasi lokal gagal disiapkan: $error');
    }
  }

  /// Data notifikasi yang diketuk saat aplikasi sudah berjalan.
  Stream<Map<String, dynamic>> get taps => _taps.stream;

  /// Data notifikasi yang membuka aplikasi dari keadaan tertutup.
  /// Hanya dikembalikan sekali.
  Future<Map<String, dynamic>?> takeLaunchData() async {
    if (!_firebaseReady || _launchTaken) return null;
    _launchTaken = true;
    try {
      final initial = await FirebaseMessaging.instance.getInitialMessage();
      if (initial != null) return initial.data;

      final details = await _local.getNotificationAppLaunchDetails();
      if (details?.didNotificationLaunchApp ?? false) {
        return _decode(details?.notificationResponse?.payload);
      }
    } catch (error) {
      debugPrint('[PushService] gagal membaca notifikasi pembuka: $error');
    }
    return null;
  }

  StreamSubscription<RemoteMessage>? _foregroundSub;
  StreamSubscription<String>? _tokenSub;
  String? _token;
  void Function()? _onMessage;

  /// Mendaftarkan perangkat milik pengguna yang sedang login.
  /// [onMessage] dipanggil saat push masuk ketika aplikasi sedang terbuka.
  Future<void> start({void Function()? onMessage}) async {
    _onMessage = onMessage;
    if (!_firebaseReady) return;

    final messaging = FirebaseMessaging.instance;
    try {
      final settings = await messaging.requestPermission();
      if (settings.authorizationStatus == AuthorizationStatus.denied) return;

      _foregroundSub ??= FirebaseMessaging.onMessage.listen((message) {
        _onMessage?.call();
        _showBanner(message);
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

  /// Saat aplikasi terbuka, FCM tidak menampilkan apa pun; banner dibuat
  /// lewat notifikasi lokal dengan kanal & ikon yang sama.
  Future<void> _showBanner(RemoteMessage message) async {
    final notification = message.notification;
    if (notification == null) return;
    try {
      await _local.show(
        id: message.messageId?.hashCode ?? DateTime.now().millisecondsSinceEpoch ~/ 1000,
        title: notification.title,
        body: notification.body,
        notificationDetails: const NotificationDetails(
          android: AndroidNotificationDetails(
            channelId,
            _channelName,
            importance: Importance.high,
            priority: Priority.high,
            icon: _icon,
            color: _accent,
          ),
          iOS: DarwinNotificationDetails(),
        ),
        payload: jsonEncode(message.data),
      );
    } catch (error) {
      debugPrint('[PushService] gagal menampilkan banner: $error');
    }
  }

  static Map<String, dynamic>? _decode(String? payload) {
    if (payload == null || payload.isEmpty) return null;
    try {
      final decoded = jsonDecode(payload);
      return decoded is Map<String, dynamic> ? decoded : null;
    } catch (_) {
      return null;
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
