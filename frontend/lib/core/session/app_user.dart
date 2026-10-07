import 'package:flutter/foundation.dart';
import 'package:rijiki/core/enums/app_permission.dart';
import 'package:rijiki/core/enums/user_role.dart';

@immutable
class AppUser {
  const AppUser({
    required this.id,
    required this.email,
    required this.role,
    required this.profileCompleted,
    this.fullName,
    this.phoneNumber,
    this.avatarUrl,
    this.permissions = const {},
    this.ownerBypass = false,
  });

  final String id;
  final String email;
  final UserRole role;
  final String? fullName;
  final String? phoneNumber;
  final String? avatarUrl;
  final bool profileCompleted;
  final Set<AppPermission> permissions;

  final bool ownerBypass;

  factory AppUser.fromAuthJson(Map<String, dynamic> json) {
    final user = json['user'] as Map<String, dynamic>;
    final rawPermissions = json['permissions'] as List<dynamic>? ?? const [];

    return AppUser(
      id: user['id'] as String,
      email: user['email'] as String,
      role: UserRole.fromJson(user['role'] as String),
      fullName: user['full_name'] as String?,
      phoneNumber: user['phone_number'] as String?,
      avatarUrl: user['avatar_url'] as String?,
      profileCompleted: user['profile_completed'] as bool? ?? false,
      permissions: rawPermissions
          .map((value) => AppPermission.tryParse(value as String))
          .whereType<AppPermission>()
          .toSet(),
      ownerBypass: json['owner_bypass'] as bool? ?? false,
    );
  }

  AppUser copyWith({
    String? fullName,
    String? phoneNumber,
    String? avatarUrl,
    bool? profileCompleted,
    Set<AppPermission>? permissions,
  }) {
    return AppUser(
      id: id,
      email: email,
      role: role,
      fullName: fullName ?? this.fullName,
      phoneNumber: phoneNumber ?? this.phoneNumber,
      avatarUrl: avatarUrl ?? this.avatarUrl,
      profileCompleted: profileCompleted ?? this.profileCompleted,
      permissions: permissions ?? this.permissions,
      ownerBypass: ownerBypass,
    );
  }
}
