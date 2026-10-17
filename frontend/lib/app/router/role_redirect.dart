import 'package:rijiki/app/router/route_paths.dart';
import 'package:rijiki/core/enums/user_role.dart';
import 'package:rijiki/core/session/app_user.dart';

abstract final class RoleRedirect {
  static const Set<String> _authRoutes = {
    RoutePaths.login,
    RoutePaths.register,
    RoutePaths.verifyEmail,
  };

  // Rute yang boleh dibuka tanpa session
  static const Set<String> _publicRoutes = {
    RoutePaths.landing,
    ..._authRoutes,
  };

  static bool needsOnboarding(AppUser user) {
    return user.role == UserRole.customer && !user.profileCompleted;
  }

  static String roleHome(AppUser user) {
    return switch (user.role) {
      UserRole.customer => RoutePaths.customerHome,
      UserRole.worker => RoutePaths.workerHome,
      UserRole.owner => RoutePaths.ownerHome,
    };
  }

  static String entryRoute(AppUser? user, {bool landingSeen = true}) {
    if (user == null) {
      return landingSeen ? RoutePaths.login : RoutePaths.landing;
    }
    return roleHome(user);
  }

  static String? guard({required AppUser? user, required String location}) {
    if (location == RoutePaths.splash) return null;

    if (user == null) {
      return _publicRoutes.contains(location) ? null : RoutePaths.login;
    }

    // User sudah login: landing tidak relevan lagi
    if (location == RoutePaths.landing) {
      return needsOnboarding(user) ? RoutePaths.onboarding : roleHome(user);
    }

    if (location == RoutePaths.login) {
      return roleHome(user);
    }

    if (location == RoutePaths.register || location == RoutePaths.verifyEmail) {
      if (needsOnboarding(user)) {
        return RoutePaths.onboarding;
      }
      return roleHome(user);
    }

    if (location == RoutePaths.onboarding) {
      if (!needsOnboarding(user)) {
        return roleHome(user);
      }
      return null;
    }

    return null;
  }
}