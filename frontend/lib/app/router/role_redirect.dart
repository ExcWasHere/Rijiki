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

  static String entryRoute(AppUser? user) {
    if (user == null) return RoutePaths.login;
    if (needsOnboarding(user)) return RoutePaths.onboarding;
    return switch (user.role) {
      UserRole.customer => RoutePaths.customerHome,
      UserRole.worker => RoutePaths.workerHome,
      UserRole.owner => RoutePaths.ownerHome,
    };
  }

  static String? guard({required AppUser? user, required String location}) {
    if (location == RoutePaths.splash) return null;

    final isAuthRoute = _authRoutes.contains(location);

    if (user == null) return isAuthRoute ? null : RoutePaths.login;
    if (isAuthRoute) return entryRoute(user);

    final onboarding = needsOnboarding(user);
    if (location == RoutePaths.onboarding && !onboarding) return entryRoute(user);
    if (onboarding && location != RoutePaths.onboarding) {
      return RoutePaths.onboarding;
    }
    return null;
  }
}
