import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:rijiki/core/error/failure.dart';
import 'package:rijiki/core/theme/app_colors.dart';
import 'package:rijiki/core/theme/app_spacing.dart';
import 'package:rijiki/features/order/domain/assignable_worker.dart';
import 'package:rijiki/features/order/presentation/controllers/staff_order_controller.dart';
import 'package:rijiki/shared/widgets/empty_state.dart';
import 'package:rijiki/shared/widgets/error_state.dart';
import 'package:rijiki/shared/widgets/loading_skeleton.dart';

class AssignChoice {
  const AssignChoice(this.workerId);

  final String? workerId;
}

Future<AssignChoice?> showAssignWorkerSheet(
  BuildContext context, {
  String? currentWorkerId,
}) {
  return showModalBottomSheet<AssignChoice>(
    context: context,
    isScrollControlled: true,
    showDragHandle: true,
    builder: (_) => _AssignWorkerSheet(currentWorkerId: currentWorkerId),
  );
}

class _AssignWorkerSheet extends ConsumerWidget {
  const _AssignWorkerSheet({this.currentWorkerId});

  final String? currentWorkerId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final workers = ref.watch(assignableWorkersProvider);
    final textTheme = Theme.of(context).textTheme;
    final maxHeight = MediaQuery.sizeOf(context).height * 0.7;

    return SafeArea(
      child: ConstrainedBox(
        constraints: BoxConstraints(maxHeight: maxHeight),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(
                AppSpacing.lg,
                0,
                AppSpacing.lg,
                AppSpacing.sm,
              ),
              child: Text('Pilih worker', style: textTheme.titleMedium),
            ),
            Flexible(
              child: workers.when(
                loading: () => const Padding(
                  padding: EdgeInsets.all(AppSpacing.lg),
                  child: LoadingSkeleton(height: 120),
                ),
                error: (error, _) => Padding(
                  padding: const EdgeInsets.all(AppSpacing.lg),
                  child: ErrorState(
                    message: error is Failure
                        ? error.message
                        : 'Daftar worker gagal dimuat. Coba lagi ya.',
                    onRetry: () => ref.invalidate(assignableWorkersProvider),
                  ),
                ),
                data: (items) => _WorkerList(
                  workers: items,
                  currentWorkerId: currentWorkerId,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _WorkerList extends StatelessWidget {
  const _WorkerList({required this.workers, required this.currentWorkerId});

  final List<AssignableWorker> workers;
  final String? currentWorkerId;

  @override
  Widget build(BuildContext context) {
    if (workers.isEmpty) {
      return const Padding(
        padding: EdgeInsets.all(AppSpacing.lg),
        child: EmptyState(
          icon: Icons.people_outline_rounded,
          title: 'Belum ada worker aktif',
          message: 'Tambahkan worker di menu Manajemen terlebih dulu.',
        ),
      );
    }

    return ListView(
      shrinkWrap: true,
      children: [
        for (final worker in workers)
          ListTile(
            leading: CircleAvatar(
              backgroundColor: AppColors.primary.withValues(alpha: 0.2),
              foregroundColor: AppColors.primaryDark,
              child: Text(
                worker.fullName.isEmpty
                    ? '?'
                    : String.fromCharCode(worker.fullName.runes.first)
                          .toUpperCase(),
              ),
            ),
            title: Text(worker.fullName),
            subtitle: Text(
              [worker.employeeCode, worker.division]
                  .where((part) => part.isNotEmpty)
                  .join(' · '),
            ),
            trailing: worker.id == currentWorkerId
                ? const Icon(Icons.check_circle_rounded, color: AppColors.success)
                : null,
            onTap: () => Navigator.pop(context, AssignChoice(worker.id)),
          ),
        if (currentWorkerId != null) ...[
          const Divider(),
          ListTile(
            leading: const Icon(Icons.person_off_outlined, color: AppColors.error),
            title: const Text(
              'Lepas assign',
              style: TextStyle(color: AppColors.error),
            ),
            subtitle: const Text('Order kembali ke antrean belum diambil'),
            onTap: () => Navigator.pop(context, const AssignChoice(null)),
          ),
        ],
      ],
    );
  }
}
