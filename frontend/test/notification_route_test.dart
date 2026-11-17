import 'package:flutter_test/flutter_test.dart';
import 'package:rijiki/app/router/route_paths.dart';
import 'package:rijiki/core/enums/user_role.dart';
import 'package:rijiki/features/notifications/domain/app_notification.dart';
import 'package:rijiki/features/notifications/presentation/utils/notification_route.dart';

void main() {
  group('notificationTarget', () {
    test('notif order membuka detail order sesuai role', () {
      const data = {'order_id': 'abc'};
      for (final (role, expected) in [
        (UserRole.customer, RoutePaths.orderDetailFor('abc')),
        (UserRole.worker, RoutePaths.workerOrderDetailFor('abc')),
        (UserRole.owner, RoutePaths.ownerOrderDetailFor('abc')),
      ]) {
        expect(
          notificationTarget(
            role: role,
            type: AppNotificationType.orderNew,
            data: data,
          ),
          expected,
        );
      }
    });

    test('tukar poin: customer ke Event & Promo, owner ke daftar pengajuan', () {
      expect(
        notificationTarget(
          role: UserRole.customer,
          type: AppNotificationType.pointRedemption,
          data: const {'status': 'approved'},
        ),
        RoutePaths.customerEvents,
      );
      expect(
        notificationTarget(
          role: UserRole.owner,
          type: AppNotificationType.pointRedemptionRequest,
          data: const {'redemption_id': 'r1'},
        ),
        RoutePaths.managementPointRedemptions,
      );
    });

    test('tipe tak dikenal tanpa order_id tidak punya tujuan', () {
      expect(
        notificationTarget(
          role: UserRole.customer,
          type: AppNotificationType.fromJson('something_new'),
          data: const {},
        ),
        isNull,
      );
    });
  });

  test('rute di dalam shell dibuka dengan go, sisanya push', () {
    expect(isShellRoute(RoutePaths.orderDetailFor('x')), isTrue);
    expect(isShellRoute(RoutePaths.ownerOrderDetailFor('x')), isTrue);
    expect(isShellRoute(RoutePaths.managementPointRedemptions), isFalse);
    expect(isShellRoute(RoutePaths.notifications), isFalse);
  });
}
