import 'package:rijiki/app/router/route_paths.dart';
import 'package:rijiki/core/constants/app_constants.dart';
import 'package:rijiki/core/enums/user_role.dart';
import 'package:rijiki/core/session/app_user.dart';

abstract final class RoleRedirect {
  static const Set<String> _authRoutes = {
    RoutePaths.login,
    RoutePaths.register,
    RoutePaths.verifyEmail,
  };

  static const Set<String> _publicRoutes = {
    RoutePaths.landing,
    ..._authRoutes,
  };

  /// Prefix route yang boleh diakses tiap role. Route di luar daftar ini
  /// dianggap tidak dikenal untuk role tersebut dan dikembalikan ke beranda.
  /// Owner tidak dibatasi.
  ///
  /// Worker tetap boleh membuka `/management/*` karena hub manajemen dipakai
  /// bersama owner dan worker berizin; izin per fitur tetap dicek backend dan
  /// menu yang tidak berizin disembunyikan.
  static const Map<UserRole, List<String>> _allowedPrefixes = {
    UserRole.customer: ['/customer', '/profile'],
    UserRole.worker: ['/worker', '/profile', '/management'],
  };

  static bool _matchesPrefix(String location, String prefix) {
    return location == prefix || location.startsWith('$prefix/');
  }

  static bool _isAllowed(UserRole role, String location) {
    if (role == UserRole.owner) return true;
    final prefixes = _allowedPrefixes[role];
    if (prefixes == null) return false;
    return prefixes.any((prefix) => _matchesPrefix(location, prefix));
  }

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

    // Scan masih memakai model tiruan (model asli belum selesai): route-nya
    // hanya terbuka di build debug, meski tautan dibuka langsung.
    if (!AppConstants.scanEnabled &&
        (location == RoutePaths.customerScan ||
            location.startsWith('${RoutePaths.customerScan}/'))) {
      return roleHome(user);
    }

    if (!_isAllowed(user.role, location)) {
      return roleHome(user);
    }

    return null;
  }
}
