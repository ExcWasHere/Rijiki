import 'package:rijiki/core/enums/app_permission.dart';
import 'package:rijiki/core/enums/user_role.dart';
import 'package:rijiki/core/session/app_user.dart';

abstract final class AccessPolicy {
  static bool isStaff(AppUser? user) =>
      user != null && (user.role == UserRole.worker || user.role == UserRole.owner);

  static bool canManageAllOrders(AppUser? user) {
    if (user == null) return false;
    return user.ownerBypass ||
        user.role == UserRole.owner ||
        user.permissions.contains(AppPermission.manageOrdersAll);
  }
}
