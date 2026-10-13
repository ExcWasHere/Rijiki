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
  });
}
