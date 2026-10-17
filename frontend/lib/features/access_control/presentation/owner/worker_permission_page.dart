import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:rijiki/core/enums/app_permission.dart';
import 'package:rijiki/core/theme/app_colors.dart';
import 'package:rijiki/core/theme/app_spacing.dart';
import 'package:rijiki/features/access_control/presentation/controllers/worker_permission_controller.dart';
import 'package:rijiki/features/access_control/presentation/utils/permission_ui.dart';
import 'package:rijiki/features/access_control/presentation/widgets/permission_group_card.dart';
import 'package:rijiki/features/worker_management/presentation/controllers/worker_list_controller.dart';
import 'package:rijiki/shared/widgets/error_state.dart';
import 'package:rijiki/shared/widgets/loading_skeleton.dart';
import 'package:rijiki/shared/widgets/state_card.dart';

class WorkerPermissionPage extends ConsumerStatefulWidget {
  const WorkerPermissionPage({super.key, required this.workerId});

  final String workerId;

  @override
  ConsumerState<WorkerPermissionPage> createState() =>
      _WorkerPermissionPageState();
}

class _WorkerPermissionPageState extends ConsumerState<WorkerPermissionPage> {
  Set<AppPermission>? _draft;

  Future<void> _save(Set<AppPermission> original) async {
    final draft = _draft;
    if (draft == null) return;

    final revoked = original.difference(draft);
    if (revoked.isNotEmpty) {
      final confirmed = await showDialog<bool>(
        context: context,
        builder: (dialogContext) => AlertDialog(
          title: const Text('Cabut hak akses?'),
          content: Text(
            'Worker tidak lagi bisa: '
            '${revoked.map((p) => p.label.toLowerCase()).join(', ')}. '
            'Perubahan berlaku pada permintaan berikutnya.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext, false),
              child: const Text('Batal'),
            ),
            TextButton(
              onPressed: () => Navigator.pop(dialogContext, true),
              child: const Text('Cabut dan simpan'),
            ),
          ],
        ),
      );
      if (confirmed != true || !mounted) return;
    }

    final messenger = ScaffoldMessenger.of(context);
    final router = GoRouter.of(context);

    final ok = await ref
        .read(permissionSaveProvider.notifier)
        .save(widget.workerId, draft);
    if (!mounted) return;

    final message = ok
        ? 'Hak akses disimpan.'
        : (ref.read(permissionSaveProvider).errorMessage ?? 'Gagal menyimpan.');
    messenger
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(message)));
    if (ok) router.pop();
  }

  @override
  Widget build(BuildContext context) {
    final worker = ref.watch(workerSummaryProvider(widget.workerId))?.profile;
    final async = ref.watch(workerPermissionsProvider(widget.workerId));
    final saving = ref.watch(permissionSaveProvider).saving;
    final list = async.value;
    final textTheme = Theme.of(context).textTheme;

    final Set<AppPermission> original = list == null
        ? <AppPermission>{}
        : {for (final p in list) p.permission};
    if (list != null) _draft ??= {...original};
    final draft = _draft ?? const <AppPermission>{};
    final changed = list != null && !_sameSet(original, draft);

    Widget body;
    if (list != null) {
      body = ListView(
        padding: const EdgeInsets.fromLTRB(
          AppSpacing.lg,
          AppSpacing.md,
          AppSpacing.lg,
          AppSpacing.xl,
        ),
        children: [
          Container(
            padding: const EdgeInsets.all(AppSpacing.md),
            decoration: BoxDecoration(
              color: AppColors.primary.withValues(alpha: 0.18),
              borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Icon(
                  Icons.info_outline_rounded,
                  color: AppColors.primaryDark,
                ),
                const SizedBox(width: AppSpacing.sm + 4),
                Expanded(
                  child: Text(
                    'Izin diberikan per worker, di atas akses dasar worker. '
                    'Owner otomatis punya semua izin, dan hanya Owner yang bisa '
                    'mengubah hak akses.',
                    style: textTheme.bodySmall,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.lg),
          for (final group in permissionGroups) ...[
            PermissionGroupCard(
              group: group,
              granted: draft,
              onChanged: saving
                  ? null
                  : (permission, value) => setState(() {
                      final next = {...draft};
                      value ? next.add(permission) : next.remove(permission);
                      _draft = next;
                    }),
            ),
            const SizedBox(height: AppSpacing.md),
          ],
        ],
      );
    } else if (async.hasError) {
      body = Padding(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: StateCard(
          child: ErrorState(
            message: 'Gagal memuat hak akses.',
            onRetry: () =>
                ref.invalidate(workerPermissionsProvider(widget.workerId)),
          ),
        ),
      );
    } else {
      body = const Padding(
        padding: EdgeInsets.all(AppSpacing.lg),
        child: LoadingSkeleton(height: 420, radius: AppSpacing.radiusLg),
      );
    }

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text(
          worker == null ? 'Hak akses' : 'Hak akses · ${worker.fullName}',
        ),
      ),
      body: body,
      bottomNavigationBar: changed
          ? Material(
              color: AppColors.surface,
              elevation: 8,
              shadowColor: Colors.black26,
              child: SafeArea(
                top: false,
                child: Padding(
                  padding: const EdgeInsets.all(AppSpacing.md),
                  child: Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          onPressed: saving
                              ? null
                              : () => setState(() => _draft = {...original}),
                          style: OutlinedButton.styleFrom(
                            minimumSize: const Size(0, 48),
                          ),
                          child: const Text('Reset'),
                        ),
                      ),
                      const SizedBox(width: AppSpacing.sm + 4),
                      Expanded(
                        flex: 2,
                        child: FilledButton(
                          onPressed: saving ? null : () => _save(original),
                          style: FilledButton.styleFrom(
                            minimumSize: const Size(0, 48),
                          ),
                          child: saving
                              ? const SizedBox(
                                  width: 20,
                                  height: 20,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    color: AppColors.onPrimary,
                                  ),
                                )
                              : const Text('Simpan perubahan'),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            )
          : null,
    );
  }

  static bool _sameSet(Set<AppPermission> a, Set<AppPermission> b) =>
      a.length == b.length && a.containsAll(b);
}
