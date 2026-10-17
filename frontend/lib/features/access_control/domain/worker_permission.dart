import 'package:flutter/foundation.dart';
import 'package:rijiki/core/enums/app_permission.dart';

@immutable
class WorkerPermission {
  const WorkerPermission({
    required this.permission,
    required this.grantedAt,
    this.grantedByName,
  });

  final AppPermission permission;
  final DateTime grantedAt;
  final String? grantedByName;
}
