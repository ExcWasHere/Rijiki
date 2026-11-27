import 'package:go_router/go_router.dart';
import 'package:rijiki/app/router/route_paths.dart';
import 'package:rijiki/core/enums/user_role.dart';
import 'package:rijiki/features/notifications/domain/app_notification.dart';

/// Halaman tujuan saat notifikasi diketuk, dipakai inbox dan push (FCM).
/// null = tidak ada halaman khusus.
String? notificationTarget({
  required UserRole role,
  required AppNotificationType type,
  required Map<String, dynamic> data,
}) {
  final orderId = data['order_id'];
  if (orderId is String && orderId.isNotEmpty) {
    // Notifikasi chat membuka percakapan order, bukan detail order.
    if (type == AppNotificationType.orderMessage) {
      return switch (role) {
        UserRole.customer => RoutePaths.orderChatFor(orderId),
        UserRole.worker => RoutePaths.workerOrderChatFor(orderId),
        UserRole.owner => RoutePaths.ownerOrderChatFor(orderId),
      };
    }
    return switch (role) {
      UserRole.customer => RoutePaths.orderDetailFor(orderId),
      UserRole.worker => RoutePaths.workerOrderDetailFor(orderId),
      UserRole.owner => RoutePaths.ownerOrderDetailFor(orderId),
    };
  }

  return switch (type) {
    AppNotificationType.pointRedemption when role == UserRole.customer =>
      RoutePaths.customerEvents,
    AppNotificationType.pointRedemptionRequest when role != UserRole.customer =>
      RoutePaths.managementPointRedemptions,
    _ => null,
  };
}

/// Membuka halaman tujuan push yang diketuk; tanpa tujuan khusus, inbox
/// notifikasi yang dibuka.
void openPushData(GoRouter router, UserRole role, Map<String, dynamic> data) {
  final target = notificationTarget(
    role: role,
    type: AppNotificationType.fromJson(data['type'] as String?),
    data: data,
  );
  openNotificationTarget(router, target ?? RoutePaths.notifications);
}

/// Rute di dalam shell tab (customer/worker/owner) wajib dibuka dengan `go`:
/// `push` dari halaman di luar shell (mis. inbox notifikasi) membangun shell
/// kedua dan memicu galat GlobalKey ganda (layar merah). Halaman di luar
/// shell tetap `push` agar tombol kembali mengarah ke halaman sebelumnya.
void openNotificationTarget(GoRouter router, String target) {
  if (isShellRoute(target)) {
    router.go(target);
  } else {
    router.push(target);
  }
}

bool isShellRoute(String location) {
  for (final root in const [
    RoutePaths.customerHome,
    RoutePaths.workerHome,
    RoutePaths.ownerHome,
  ]) {
    if (location == root || location.startsWith('$root/')) return true;
  }
  return false;
}
