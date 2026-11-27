import 'package:flutter_test/flutter_test.dart';
import 'package:rijiki/app/router/role_redirect.dart';
import 'package:rijiki/app/router/route_paths.dart';
import 'package:rijiki/core/enums/user_role.dart';
import 'package:rijiki/core/session/app_user.dart';

void main() {
  const customerNotCompleted = AppUser(
    id: 'user-1',
    email: 'new@rijiki.id',
    role: UserRole.customer,
    profileCompleted: false,
  );

  const customerCompleted = AppUser(
    id: 'user-2',
    email: 'old@rijiki.id',
    role: UserRole.customer,
    profileCompleted: true,
  );

  group('RoleRedirect', () {
    test('Unauthenticated user is redirected to login for protected routes', () {
      expect(RoleRedirect.guard(user: null, location: RoutePaths.customerHome), RoutePaths.login);
      expect(RoleRedirect.guard(user: null, location: RoutePaths.onboarding), RoutePaths.login);
      expect(RoleRedirect.guard(user: null, location: RoutePaths.login), isNull);
    });

    test('Logged in user on login page is redirected to customer home (never onboarding)', () {
      expect(
        RoleRedirect.guard(user: customerNotCompleted, location: RoutePaths.login),
        RoutePaths.customerHome,
      );
      expect(
        RoleRedirect.guard(user: customerCompleted, location: RoutePaths.login),
        RoutePaths.customerHome,
      );
    });

    test('Onboarding only triggers when finishing account creation (register / verify-email)', () {
      expect(
        RoleRedirect.guard(user: customerNotCompleted, location: RoutePaths.register),
        RoutePaths.onboarding,
      );
      expect(
        RoleRedirect.guard(user: customerNotCompleted, location: RoutePaths.verifyEmail),
        RoutePaths.onboarding,
      );
    });

    test('If profile is completed, accessing onboarding redirects to customer home', () {
      expect(
        RoleRedirect.guard(user: customerCompleted, location: RoutePaths.onboarding),
        RoutePaths.customerHome,
      );
    });

    test('Logged in user stays on customer home without being redirected to onboarding', () {
      expect(
        RoleRedirect.guard(user: customerNotCompleted, location: RoutePaths.customerHome),
        isNull,
      );
      expect(
        RoleRedirect.guard(user: customerCompleted, location: RoutePaths.customerHome),
        isNull,
      );
    });

    test('Customer tidak bisa membuka halaman owner maupun worker lewat tautan langsung', () {
      for (final location in [
        RoutePaths.ownerHome,
        RoutePaths.ownerOrders,
        RoutePaths.ownerFinance,
        RoutePaths.ownerWorkers,
        RoutePaths.workerHome,
        RoutePaths.workerOrders,
      ]) {
        expect(
          RoleRedirect.guard(user: customerCompleted, location: location),
          RoutePaths.customerHome,
          reason: 'customer seharusnya ditolak di $location',
        );
      }
    });

    test('Worker hanya boleh di area worker, bukan halaman owner atau order customer', () {
      const worker = AppUser(
        id: 'user-3',
        email: 'worker@rijiki.id',
        role: UserRole.worker,
        profileCompleted: true,
      );

      expect(RoleRedirect.guard(user: worker, location: RoutePaths.workerOrders), isNull);
      expect(RoleRedirect.guard(user: worker, location: RoutePaths.workerProfile), isNull);
      // Hub manajemen dipakai bersama owner; izin per fitur dicek backend.
      expect(RoleRedirect.guard(user: worker, location: RoutePaths.managementPoints), isNull);
      expect(
        RoleRedirect.guard(user: worker, location: RoutePaths.ownerFinance),
        RoutePaths.workerHome,
      );
      expect(
        RoleRedirect.guard(user: worker, location: RoutePaths.customerHome),
        RoutePaths.workerHome,
      );
    });

    test('Customer boleh membuka menu profil bersama', () {
      for (final location in [
        RoutePaths.customerOrders,
        RoutePaths.customerProfile,
        RoutePaths.editProfile,
        RoutePaths.notifications,
        RoutePaths.accountSecurity,
      ]) {
        expect(
          RoleRedirect.guard(user: customerCompleted, location: location),
          isNull,
          reason: 'customer seharusnya boleh membuka $location',
        );
      }
    });

    test('Owner bebas membuka halaman mana pun yang terdaftar', () {
      const owner = AppUser(
        id: 'user-4',
        email: 'owner@rijiki.id',
        role: UserRole.owner,
        profileCompleted: true,
      );

      expect(RoleRedirect.guard(user: owner, location: RoutePaths.ownerFinance), isNull);
      expect(RoleRedirect.guard(user: owner, location: RoutePaths.ownerWorkers), isNull);
      expect(RoleRedirect.guard(user: owner, location: RoutePaths.ownerHome), isNull);
    });
  });
}
