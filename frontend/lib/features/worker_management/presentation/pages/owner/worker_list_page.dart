import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:rijiki/app/router/route_paths.dart';
import 'package:rijiki/core/theme/app_colors.dart';
import 'package:rijiki/core/theme/app_spacing.dart';
import 'package:rijiki/features/worker_management/domain/worker_profile.dart';
import 'package:rijiki/features/worker_management/presentation/controllers/worker_list_controller.dart';
import 'package:rijiki/features/worker_management/presentation/widgets/worker_tile.dart';
import 'package:rijiki/shared/widgets/empty_state.dart';
import 'package:rijiki/shared/widgets/error_state.dart';
import 'package:rijiki/shared/widgets/loading_skeleton.dart';
import 'package:rijiki/shared/widgets/state_card.dart';

class WorkerListPage extends ConsumerStatefulWidget {
  const WorkerListPage({super.key});

  @override
  ConsumerState<WorkerListPage> createState() => _WorkerListPageState();
}

class _WorkerListPageState extends ConsumerState<WorkerListPage> {
  final TextEditingController _search = TextEditingController();

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final async = ref.watch(workersProvider);
    final all = async.value;
    final visible = ref.watch(filteredWorkersProvider);
    final divisions = ref.watch(workerDivisionsProvider);
    final filter = ref.watch(workerListFilterProvider);
    final notifier = ref.read(workerListFilterProvider.notifier);
    final textTheme = Theme.of(context).textTheme;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Worker'),
        actions: [
          IconButton(
            tooltip: 'Ringkasan KPI',
            icon: const Icon(Icons.leaderboard_rounded),
            onPressed: () => context.push(RoutePaths.ownerWorkerKpiOverview),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => context.push(RoutePaths.ownerWorkerNew),
        backgroundColor: AppColors.primary,
        foregroundColor: AppColors.onPrimary,
        icon: const Icon(Icons.person_add_alt_1_rounded),
        label: const Text('Tambah worker'),
      ),
      body: RefreshIndicator(
        color: AppColors.primaryDark,
        onRefresh: () async {
          ref.invalidate(workersProvider);
          try {
            await ref.read(workersProvider.future);
          } catch (_) {}
        },
        child: ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.fromLTRB(
            AppSpacing.lg,
            AppSpacing.md,
            AppSpacing.lg,
            96,
          ),
          children: [
            ListenableBuilder(
              listenable: _search,
              builder: (context, _) => TextField(
                controller: _search,
                onChanged: notifier.setQuery,
                textInputAction: TextInputAction.search,
                decoration: InputDecoration(
                  hintText: 'Cari nama atau kode pegawai',
                  prefixIcon: const Icon(Icons.search_rounded),
                  suffixIcon: _search.text.isEmpty
                      ? null
                      : IconButton(
                          tooltip: 'Hapus pencarian',
                          icon: const Icon(Icons.close_rounded),
                          onPressed: () {
                            _search.clear();
                            notifier.setQuery('');
                          },
                        ),
                ),
              ),
            ),
            if (divisions.isNotEmpty) ...[
              const SizedBox(height: AppSpacing.sm + 4),
              Wrap(
                spacing: AppSpacing.sm,
                runSpacing: AppSpacing.sm,
                children: [
                  _DivisionChip(
                    label: 'Semua',
                    selected: filter.division == null,
                    onTap: () => notifier.setDivision(null),
                  ),
                  for (final division in divisions)
                    _DivisionChip(
                      label: division,
                      selected: filter.division == division,
                      onTap: () => notifier.setDivision(division),
                    ),
                ],
              ),
            ],
            const SizedBox(height: AppSpacing.md),
            if (all != null)
              AnimatedOpacity(
                duration: const Duration(milliseconds: 200),
                opacity: async.isLoading ? 0.55 : 1,
                child: all.isEmpty
                    ? StateCard(
                        child: EmptyState(
                          icon: Icons.groups_rounded,
                          title: 'Belum ada worker',
                          message: 'Tambahkan worker pertama untuk outlet.',
                          actionLabel: 'Tambah worker',
                          onAction: () => context.push(RoutePaths.ownerWorkerNew),
                        ),
                      )
                    : visible.isEmpty
                    ? StateCard(
                        child: EmptyState(
                          icon: Icons.search_off_rounded,
                          title: 'Worker tidak ditemukan',
                          actionLabel: 'Reset pencarian',
                          onAction: () {
                            _search.clear();
                            notifier.reset();
                          },
                        ),
                      )
                    : Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Padding(
                            padding: const EdgeInsets.only(
                              left: AppSpacing.xs,
                              bottom: AppSpacing.sm,
                            ),
                            child: Text(
                              '${visible.length} worker',
                              style: textTheme.labelLarge?.copyWith(
                                color: AppColors.onSurfaceVariant,
                              ),
                            ),
                          ),
                          _WorkerCard(
                            workers: visible,
                            onTap: (worker) => context.push(
                              RoutePaths.ownerWorkerDetailFor(worker.id),
                            ),
                          ),
                        ],
                      ),
              )
            else if (async.hasError)
              StateCard(
                child: ErrorState(
                  message: 'Gagal memuat daftar worker.',
                  onRetry: () => ref.invalidate(workersProvider),
                ),
              )
            else
              const LoadingSkeleton(height: 360, radius: AppSpacing.radiusLg),
          ],
        ),
      ),
    );
  }
}

class _WorkerCard extends StatelessWidget {
  const _WorkerCard({required this.workers, required this.onTap});

  final List<WorkerSummary> workers;
  final ValueChanged<WorkerProfile> onTap;

  @override
  Widget build(BuildContext context) {
    return Container(
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
        border: Border.all(color: AppColors.outline.withValues(alpha: 0.3)),
      ),
      child: Material(
        color: AppColors.surface,
        child: Column(
          children: [
            for (var i = 0; i < workers.length; i++) ...[
              if (i > 0)
                Divider(
                  height: 1,
                  indent: AppSpacing.md,
                  endIndent: AppSpacing.md,
                  color: AppColors.outline.withValues(alpha: 0.2),
                ),
              WorkerTile(
                summary: workers[i],
                onTap: () => onTap(workers[i].profile),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _DivisionChip extends StatelessWidget {
  const _DivisionChip({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return ChoiceChip(
      selected: selected,
      onSelected: (_) => onTap(),
      showCheckmark: false,
      label: Text(label),
      labelStyle: textTheme.labelLarge?.copyWith(
        color: selected ? AppColors.onSurface : AppColors.onSurfaceVariant,
        fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
      ),
      backgroundColor: AppColors.surface,
      selectedColor: AppColors.primary.withValues(alpha: 0.3),
      shape: const StadiumBorder(),
      side: BorderSide(
        color: selected
            ? AppColors.primaryDark
            : AppColors.outline.withValues(alpha: 0.4),
      ),
    );
  }
}
