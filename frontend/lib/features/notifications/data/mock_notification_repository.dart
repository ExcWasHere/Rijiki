import 'package:rijiki/features/notifications/domain/app_notification.dart';
import 'package:rijiki/features/notifications/domain/notification_repository.dart';

class MockNotificationRepository implements NotificationRepository {
  MockNotificationRepository();

  static const Duration _latency = Duration(milliseconds: 400);

  final List<AppNotification> _items = [
    AppNotification(
      id: 'mock-notif-1',
      type: AppNotificationType.orderStatus,
      title: 'Sepatu sedang dibersihkan · RJK-1001-001',
      body: 'Sepatu sedang dalam proses pembersihan oleh tim Rijiki.',
      read: false,
      createdAt: DateTime.now().subtract(const Duration(minutes: 12)),
    ),
    AppNotification(
      id: 'mock-notif-2',
      type: AppNotificationType.paymentPaid,
      title: 'Pembayaran berhasil · RJK-1001-001',
      body: 'Pembayaranmu sudah kami terima.',
      read: true,
      createdAt: DateTime.now().subtract(const Duration(days: 2)),
    ),
  ];

  @override
  Future<NotificationPage> fetch({
    required int page,
    required int limit,
  }) async {
    await Future<void>.delayed(_latency);
    return NotificationPage(
      items: List.unmodifiable(_items),
      total: _items.length,
      unread: _items.where((item) => !item.read).length,
    );
  }

  @override
  Future<int> fetchUnreadCount() async {
    await Future<void>.delayed(_latency);
    return _items.where((item) => !item.read).length;
  }

  @override
  Future<int> markRead(String id) async {
    await Future<void>.delayed(_latency);
    final index = _items.indexWhere((item) => item.id == id);
    if (index >= 0) _items[index] = _items[index].copyWith(read: true);
    return _items.where((item) => !item.read).length;
  }

  @override
  Future<void> markAllRead() async {
    await Future<void>.delayed(_latency);
    for (var index = 0; index < _items.length; index++) {
      _items[index] = _items[index].copyWith(read: true);
    }
  }

  @override
  Future<void> registerDevice({
    required String token,
    required String platform,
  }) async {
    await Future<void>.delayed(_latency);
  }

  @override
  Future<void> unregisterDevice(String token) async {
    await Future<void>.delayed(_latency);
  }
}
