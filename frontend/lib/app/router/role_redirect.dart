import 'package:rijiki/app/router/route_paths.dart';
import 'package:rijiki/core/enums/user_role.dart';
import 'package:rijiki/core/session/app_user.dart';

abstract final class RoleRedirect {
  static const Set<String> _authRoutes = {
    RoutePaths.login,
    RoutePaths.register,
    RoutePaths.verifyEmail,
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

  static String entryRoute(AppUser? user) {
    if (user == null) return RoutePaths.login;
    return roleHome(user);
  }

  static String? guard({required AppUser? user, required String location}) {
    if (location == RoutePaths.splash) return null;

    final isAuthRoute = _authRoutes.contains(location);

    if (user == null) return isAuthRoute ? null : RoutePaths.login;

    // Pengguna sudah login:
    // Jika berada di halaman login, selalu arahkan langsung ke home role (tidak ke onboarding).
    if (location == RoutePaths.login) {
      return roleHome(user);
    }

    // Onboarding HANYA muncul ketika pengguna selesai membuat akun (register / verify-email).
    if (location == RoutePaths.register || location == RoutePaths.verifyEmail) {
      if (needsOnboarding(user)) {
        return RoutePaths.onboarding;
      }
      return roleHome(user);
    }

    // Jika pengguna berada di rute onboarding:
    // Jika onboarding sudah selesai atau bukan customer, arahkan ke home role.
    if (location == RoutePaths.onboarding) {
      if (!needsOnboarding(user)) {
        return roleHome(user);
      }
      return null;
    }

    return null;
  }
}
