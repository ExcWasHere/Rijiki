import 'package:flutter/material.dart';
import 'package:rijiki/core/enums/app_permission.dart';
import 'package:rijiki/core/enums/user_role.dart';
import 'package:rijiki/core/session/app_user.dart';

enum CmsSectionId { services, events, promos, merchandise, testimonials }

/// Satu bagian di hub CMS (PRD Bagian 17). Tiap bagian punya izin sendiri.
/// Rute tujuan sengaja tidak disimpan di sini karena berbeda per shell
/// (Owner dan worker punya halaman sendiri).
@immutable
class CmsSection {
  const CmsSection({
    required this.id,
    required this.title,
    required this.description,
    required this.icon,
    required this.color,
    required this.permission,
  });

  final CmsSectionId id;
  final String title;
  final String description;
  final IconData icon;
  final Color color;
  final AppPermission permission;
  bool isVisibleFor(AppUser user) {
    return switch (user.role) {
      UserRole.owner => true,
      UserRole.worker => user.permissions.contains(permission),
      UserRole.customer => false,
    };
  }
}
