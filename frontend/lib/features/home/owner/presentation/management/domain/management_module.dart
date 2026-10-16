import 'package:flutter/material.dart';
import 'package:rijiki/core/enums/app_permission.dart';
import 'package:rijiki/core/enums/user_role.dart';
import 'package:rijiki/core/session/app_user.dart';

@immutable
class ManagementModule {
  const ManagementModule({
    required this.id,
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.color,
    this.route,
    this.permissions = const {},
  });

  final String id;
  final String title;
  final String subtitle;
  final IconData icon;
  final Color color;
  final String? route;
  final Set<AppPermission> permissions;

  bool get isAvailable => route != null;

  bool isVisibleFor(AppUser user) {
    return switch (user.role) {
      UserRole.owner => true,
      UserRole.worker => permissions.any(user.permissions.contains),
      UserRole.customer => false,
    };
  }
}
