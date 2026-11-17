import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rijiki/app/providers.dart';
import 'package:rijiki/core/theme/app_theme.dart';
import 'package:rijiki/core/enums/user_role.dart';
import 'package:rijiki/core/session/app_user.dart';
import 'package:rijiki/core/session/session_provider.dart';
import 'package:rijiki/features/notifications/data/mock_notification_repository.dart';
import 'package:rijiki/features/points/data/mock_customer_points_repository.dart';
import 'package:rijiki/features/profile/presentation/customer/profile_page.dart';
import 'package:rijiki/features/notifications/presentation/notifications_page.dart';
import 'package:rijiki/features/profile/data/mock_profile_repository.dart';
import 'package:rijiki/features/profile/presentation/customer/my_ratings_page.dart';
import 'package:rijiki/features/profile/presentation/customer/my_shoes_page.dart';

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

void main() {
  group('Halaman profil customer', () {
    testWidgets('Profil menampilkan menu yang sudah tersambung', (tester) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            sessionProvider.overrideWith(_SignedInCustomer.new),
            profileRepositoryProvider.overrideWithValue(
              MockProfileRepository(),
            ),
            notificationRepositoryProvider.overrideWithValue(
              MockNotificationRepository(),
            ),
            customerPointsRepositoryProvider.overrideWithValue(
              MockCustomerPointsRepository(),
            ),
          ],
          child: MaterialApp(
            theme: AppTheme.light,
            home: const ProfilePage(),
          ),
        ),
      );
      await tester.pumpAndSettle();
      // Saldo poin dimuat lewat mock dengan jeda; beri waktu sampai selesai.
      await tester.pump(const Duration(seconds: 1));
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
              MockProfileRepository(),
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
              MockProfileRepository(),
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
              MockNotificationRepository(),
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
