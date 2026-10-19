import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:rijiki/app/providers.dart';
import 'package:rijiki/core/enums/app_permission.dart';
import 'package:rijiki/features/access_control/domain/worker_permission.dart';

final workerPermissionsProvider = FutureProvider.autoDispose
    .family<List<WorkerPermission>, String>((ref, workerId) {
      return ref.watch(permissionRepositoryProvider).fetchPermissions(workerId);
    });

@immutable
class PermissionSaveState {
  const PermissionSaveState({this.saving = false, this.errorMessage});

  final bool saving;
  final String? errorMessage;
}

class PermissionSaveNotifier extends Notifier<PermissionSaveState> {
  @override
  PermissionSaveState build() => const PermissionSaveState();
  Future<bool> save(String workerId, Set<AppPermission> permissions) async {
    if (state.saving) return false;
    state = const PermissionSaveState(saving: true);
    try {
      await ref
          .read(permissionRepositoryProvider)
          .savePermissions(workerId, permissions);
      if (!ref.mounted) return true;
      ref.invalidate(workerPermissionsProvider(workerId));
      state = const PermissionSaveState();
      return true;
    } catch (_) {
      if (!ref.mounted) return false;
      state = const PermissionSaveState(
        errorMessage: 'Gagal menyimpan hak akses. Coba lagi ya.',
      );
      return false;
    }
  }
}

final permissionSaveProvider =
    NotifierProvider.autoDispose<PermissionSaveNotifier, PermissionSaveState>(
      PermissionSaveNotifier.new,
    );
