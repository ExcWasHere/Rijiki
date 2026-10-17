import 'package:rijiki/core/enums/app_permission.dart';
import 'package:rijiki/features/access_control/domain/worker_permission.dart';

abstract interface class PermissionRepository {
  Future<List<WorkerPermission>> fetchPermissions(String workerId);
  Future<void> savePermissions(String workerId, Set<AppPermission> permissions);
}
