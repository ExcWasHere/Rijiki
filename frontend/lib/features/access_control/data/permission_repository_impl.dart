import 'package:rijiki/core/constants/app_strings.dart';
import 'package:rijiki/core/enums/app_permission.dart';
import 'package:rijiki/core/error/app_exception.dart';
import 'package:rijiki/core/error/failure.dart';
import 'package:rijiki/core/network/api_client.dart';
import 'package:rijiki/core/network/api_endpoint.dart';
import 'package:rijiki/features/access_control/domain/permission_repository.dart';
import 'package:rijiki/features/access_control/domain/worker_permission.dart';

/// Izin delegasi worker dari backend (`/api/owner/workers/:id/permissions`).
/// Hanya owner yang boleh membaca dan menulis. Backend langsung memberlakukan
/// perubahan, tetapi menu di aplikasi worker baru ikut berubah setelah
/// sesinya dimuat ulang (login atau /me).
class PermissionRepositoryImpl implements PermissionRepository {
  PermissionRepositoryImpl({required this.api});

  final ApiClient api;

  @override
  Future<List<WorkerPermission>> fetchPermissions(String workerId) async {
    try {
      final json = await api.get(
        ApiEndpoints.workerPermissions(workerId),
        auth: true,
      );
      return _parse(json);
    } on AppException catch (e) {
      throw _toFailure(e);
    }
  }

  @override
  Future<void> savePermissions(
    String workerId,
    Set<AppPermission> permissions,
  ) async {
    try {
      await api.put(
        ApiEndpoints.workerPermissions(workerId),
        auth: true,
        body: {
          'permissions': [for (final p in permissions) p.value],
        },
      );
    } on AppException catch (e) {
      throw _toFailure(e);
    }
  }

  static List<WorkerPermission> _parse(Map<String, dynamic> json) {
    final raw = json['grants'] as List<dynamic>? ?? const [];
    final result = <WorkerPermission>[];
    for (final item in raw) {
      final map = item as Map<String, dynamic>;
      final permission = AppPermission.tryParse(map['permission'] as String);
      if (permission == null) continue; // izin dari versi backend yang lebih baru
      result.add(
        WorkerPermission(
          permission: permission,
          grantedAt: DateTime.parse(map['granted_at'] as String).toLocal(),
          grantedByName: map['granted_by_name'] as String?,
        ),
      );
    }
    return result;
  }

  Failure _toFailure(AppException e) {
    switch (e.code) {
      case AppException.networkCode:
      case AppException.offlineCode:
      case AppException.timeoutCode:
        return Failure(FailureType.network, e.message, code: e.code);
      case 'unauthorized':
        return Failure(FailureType.unauthorized, e.message, code: e.code);
      case 'validation_error':
        return Failure(FailureType.validation, e.message, code: e.code);
    }
    if ((e.statusCode ?? 0) >= 500) {
      return Failure(FailureType.server, e.message, code: e.code);
    }
    return Failure(
      FailureType.unknown,
      e.message.isEmpty ? AppStrings.errUnknown : e.message,
      code: e.code,
    );
  }
}
