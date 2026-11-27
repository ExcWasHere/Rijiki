import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rijiki/app/providers.dart';
import 'package:rijiki/core/enums/user_role.dart';
import 'package:rijiki/core/session/app_user.dart';
import 'package:rijiki/core/session/session_provider.dart';
import 'package:rijiki/core/theme/app_theme.dart';
import 'package:rijiki/features/notifications/domain/app_notification.dart';
import 'package:rijiki/features/notifications/domain/notification_repository.dart';
import 'package:rijiki/features/notifications/presentation/pages/notifications_page.dart';
import 'package:rijiki/features/points/domain/customer_points_repository.dart';
import 'package:rijiki/features/points/domain/point_ledger_entry.dart';
import 'package:rijiki/features/points/domain/point_redemption.dart';
import 'package:rijiki/features/points/domain/reward.dart';
import 'package:rijiki/features/profile/domain/profile_history.dart';
import 'package:rijiki/features/profile/domain/profile_repository.dart';
import 'package:rijiki/features/profile/presentation/pages/customer/my_ratings_page.dart';
import 'package:rijiki/features/profile/presentation/pages/customer/my_shoes_page.dart';
import 'package:rijiki/features/profile/presentation/pages/customer/profile_page.dart';

/// Fake lokal: dulu test ini memakai `lib/features/**/data/mock_*.dart`, yang
/// sudah dihapus supaya tidak ada data tiruan di build produksi.
class _SignedInCustomer extends SessionNotifier {
  @override
  AppUser? build() => const AppUser(
    id: 'user-test',
    email: 'budi@rijiki.id',
    role: UserRole.customer,
    fullName: 'Budi Santoso',
    profileCompleted: true,
  );
}

class _FakeProfileRepository implements ProfileRepository {
  @override
  Future<MyShoePage> fetchMyShoes({required int page, required int limit}) async {
    return MyShoePage(
      total: 2,
      items: [
        MyShoe(
          id: 'shoe-1',
          orderId: 'order-1',
          orderNumber: 'RJK-1001-001',
          orderStatus: 'completed',
          serviceName: 'Deep Clean',
          shoeBrand: 'Nike Air Force 1',
          quantity: 2,
          orderDate: DateTime(2026, 11, 18),
        ),
      ],
    );
  }

  @override
  Future<CustomerRatingPage> fetchMyRatings({
    required int page,
    required int limit,
  }) async {
    return CustomerRatingPage(
      total: 1,
      average: 5,
      items: [
        CustomerRating(
          id: 'rating-1',
          orderId: 'order-1',
          orderNumber: 'RJK-1001-001',
          workerName: 'Andi',
          ratingValue: 5,
          comment: 'Bersih banget, wanginya enak.',
          isFeatured: true,
          createdAt: DateTime(2026, 11, 18),
        ),
      ],
    );
  }

  @override
  Future<AppUser> saveCustomerProfile({
    required AppUser currentUser,
    required String fullName,
    required String phoneNumber,
    required String address,
    required double latitude,
    required double longitude,
  }) async => currentUser;

  @override
  Future<AppUser> saveProfile({
    required AppUser currentUser,
    required String fullName,
    required String phoneNumber,
  }) async => currentUser;

  @override
  Future<AppUser> uploadAvatar({
    required AppUser currentUser,
    required String filePath,
  }) async => currentUser;
}

class _FakeNotificationRepository implements NotificationRepository {
  final List<AppNotification> _items = [
    AppNotification(
      id: 'notif-1',
      type: AppNotificationType.orderStatus,
      title: 'Order diperbarui',
      body: 'Sepatu sedang dibersihkan',
      read: false,
      createdAt: DateTime(2026, 11, 18, 10),
    ),
    AppNotification(
      id: 'notif-2',
      type: AppNotificationType.paymentPaid,
      title: 'Pembayaran diterima',
      body: 'Pembayaran berhasil',
      read: true,
      createdAt: DateTime(2026, 11, 18, 9),
    ),
  ];

  @override
  Future<NotificationPage> fetch({required int page, required int limit}) async {
    return NotificationPage(
      items: _items,
      total: _items.length,
      unread: _items.where((item) => !item.read).length,
    );
  }

  @override
  Future<int> fetchUnreadCount() async =>
      _items.where((item) => !item.read).length;

  @override
  Future<int> markRead(String id) async {
    final index = _items.indexWhere((item) => item.id == id);
    if (index >= 0) _items[index] = _items[index].copyWith(read: true);
    return _items.where((item) => !item.read).length;
  }

  @override
  Future<void> markAllRead() async {
    for (var i = 0; i < _items.length; i++) {
      _items[i] = _items[i].copyWith(read: true);
    }
  }

  @override
  Future<void> registerDevice({
    required String token,
    required String platform,
  }) async {}

  @override
  Future<void> unregisterDevice(String token) async {}
}

class _FakeCustomerPointsRepository implements CustomerPointsRepository {
  @override
  Future<PointBalance> fetchBalance() async =>
      const PointBalance(balance: 120);

  @override
  Future<PointLedgerPage> fetchLedger({
    required int page,
    required int limit,
  }) async => const PointLedgerPage(items: [], total: 0);

  @override
  Future<List<Reward>> fetchRewards() async => const [];

  @override
  Future<List<PointRedemption>> fetchRedemptions({
    RedemptionStatus? status,
    int limit = 50,
  }) async => const [];

  @override
  Future<PointRedemption> requestRedemption(String merchandiseId) =>
      throw UnimplementedError();
}

void main() {
  group('Halaman profil customer', () {
    testWidgets('Profil menampilkan menu yang sudah tersambung', (tester) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            sessionProvider.overrideWith(_SignedInCustomer.new),
            profileRepositoryProvider.overrideWithValue(
              _FakeProfileRepository(),
            ),
            notificationRepositoryProvider.overrideWithValue(
              _FakeNotificationRepository(),
            ),
            customerPointsRepositoryProvider.overrideWithValue(
              _FakeCustomerPointsRepository(),
            ),
          ],
          child: MaterialApp(
            theme: AppTheme.light,
            home: const ProfilePage(),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Budi Santoso'), findsOneWidget);
      expect(find.text('Notifikasi'), findsOneWidget);
      expect(find.text('Sepatu saya'), findsOneWidget);
      expect(find.text('Rating & testimoni'), findsOneWidget);
      expect(find.text('Pusat bantuan'), findsOneWidget);
      expect(find.text('Syarat & ketentuan'), findsOneWidget);
      // Poin dari repository tampil sebagai angka, bukan teks statis.
      expect(find.textContaining('poin'), findsWidgets);
    });

    testWidgets('Sepatu saya menampilkan sepatu dari riwayat order', (
      tester,
    ) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            profileRepositoryProvider.overrideWithValue(
              _FakeProfileRepository(),
            ),
          ],
          child: MaterialApp(theme: AppTheme.light, home: const MyShoesPage()),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Nike Air Force 1'), findsOneWidget);
      expect(find.textContaining('RJK-1001-001'), findsOneWidget);
      expect(find.text('2 sepatu pernah dicuci di Rijiki.'), findsOneWidget);
    });

    testWidgets('Rating & testimoni menampilkan rata-rata dan ulasan', (
      tester,
    ) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            profileRepositoryProvider.overrideWithValue(
              _FakeProfileRepository(),
            ),
          ],
          child: MaterialApp(
            theme: AppTheme.light,
            home: const MyRatingsPage(),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('5.0 dari 5'), findsOneWidget);
      expect(find.text('Bersih banget, wanginya enak.'), findsOneWidget);
      expect(find.text('Tampil di beranda'), findsOneWidget);
    });

    testWidgets('Notifikasi menampilkan pesan dan aksi tandai dibaca', (
      tester,
    ) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            notificationRepositoryProvider.overrideWithValue(
              _FakeNotificationRepository(),
            ),
          ],
          child: MaterialApp(
            theme: AppTheme.light,
            home: const NotificationsPage(),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.textContaining('Sepatu sedang dibersihkan'), findsOneWidget);
      expect(find.textContaining('Pembayaran berhasil'), findsOneWidget);
      expect(find.text('Tandai dibaca'), findsOneWidget);
    });
  });
}
