import 'package:rijiki/core/enums/app_permission.dart';
import 'package:rijiki/core/mock/mock_scenario.dart';
import 'package:rijiki/features/access_control/domain/permission_repository.dart';
import 'package:rijiki/features/access_control/domain/worker_permission.dart';

class MockPermissionRepository implements PermissionRepository {
  MockPermissionRepository({this.scenario = MockScenario.data});

  final MockScenario scenario;

  static const Duration _writeLatency = Duration(milliseconds: 450);
  static const String _owner = 'Owner Rijiki';

  late final Map<String, Map<AppPermission, WorkerPermission>> _grants = _seed();

  @override
  Future<List<WorkerPermission>> fetchPermissions(String workerId) {
    return scenario.resolve<List<WorkerPermission>>(
      empty: const [],
      data: [...(_grants[workerId]?.values ?? const <WorkerPermission>[])],
    );
  }

  @override
  Future<void> savePermissions(
    String workerId,
    Set<AppPermission> permissions,
  ) async {
    await Future<void>.delayed(_writeLatency);
    if (scenario == MockScenario.error) throw const MockException();

    final current = _grants.putIfAbsent(workerId, () => {});
    current.removeWhere((permission, _) => !permissions.contains(permission));
    for (final permission in permissions) {
      current.putIfAbsent(
        permission,
        () => WorkerPermission(
          permission: permission,
          grantedAt: DateTime.now(),
          grantedByName: _owner,
        ),
      );
    }
  }

  static Map<String, Map<AppPermission, WorkerPermission>> _seed() {
    final now = DateTime.now();
    WorkerPermission grant(AppPermission p, int daysAgo) => WorkerPermission(
      permission: p,
      grantedAt: now.subtract(Duration(days: daysAgo)),
      grantedByName: _owner,
    );

    return {
      'wrk-2': {
        AppPermission.manageCmsServices: grant(AppPermission.manageCmsServices, 40),
        AppPermission.manageCmsEvents: grant(AppPermission.manageCmsEvents, 40),
      },
      'wrk-4': {
        AppPermission.manageFinance: grant(AppPermission.manageFinance, 12),
        AppPermission.viewAnalytics: grant(AppPermission.viewAnalytics, 12),
      },
    };
  }
}
