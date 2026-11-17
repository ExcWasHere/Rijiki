import 'package:rijiki/features/notifications/domain/app_notification.dart';

/// Inbox notifikasi semua role. Ditulis backend dari peristiwa order,
/// pembayaran, dan poin; push FCM hanya pelengkap.
abstract interface class NotificationRepository {
  Future<NotificationPage> fetch({
    required int page,
    required int limit,
  });

  Future<int> fetchUnreadCount();

  /// Menandai satu notifikasi dibaca; mengembalikan sisa yang belum dibaca.
  Future<int> markRead(String id);

  Future<void> markAllRead();

  /// Mendaftarkan token FCM perangkat ke backend.
  Future<void> registerDevice({required String token, required String platform});

  /// Melepas token perangkat (dipanggil saat keluar).
  Future<void> unregisterDevice(String token);
}
