import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:rijiki/app/router/route_paths.dart';
import 'package:rijiki/core/theme/app_colors.dart';
import 'package:rijiki/core/theme/app_spacing.dart';
import 'package:rijiki/features/worker_management/presentation/controllers/worker_kpi_controller.dart';
import 'package:rijiki/features/worker_management/presentation/utils/worker_format.dart';
import 'package:rijiki/features/worker_management/presentation/widgets/kpi_period_picker.dart';
import 'package:rijiki/features/worker_management/presentation/widgets/kpi_score_card.dart';
import 'package:rijiki/features/worker_management/presentation/widgets/worker_avatar.dart';
import 'package:rijiki/shared/widgets/empty_state.dart';
import 'package:rijiki/shared/widgets/error_state.dart';
import 'package:rijiki/shared/widgets/loading_skeleton.dart';
import 'package:rijiki/shared/widgets/state_card.dart';

class KpiOverviewPage extends ConsumerWidget {
  const KpiOverviewPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final period = ref.watch(kpiPeriodProvider);
    final notifier = ref.read(kpiPeriodProvider.notifier);
    final async = ref.watch(kpiOverviewProvider(period));
    final rows = async.value;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(title: const Text('Ringkasan KPI')),
      body: RefreshIndicator(
        color: AppColors.primaryDark,
        onRefresh: () async {
          ref.invalidate(kpiOverviewProvider(period));
          try {
            await ref.read(kpiOverviewProvider(period).future);
          } catch (_) {}
        },
        child: ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.fromLTRB(
            AppSpacing.lg,
            AppSpacing.md,
            AppSpacing.lg,
            AppSpacing.xl,
          ),
          children: [
            KpiPeriodPicker(
              period: period,
              onPrevious: notifier.previous,
              onNext: notifier.next,
            ),
            const SizedBox(height: AppSpacing.md),
            if (rows != null)
              AnimatedOpacity(
                duration: const Duration(milliseconds: 200),
                opacity: async.isLoading ? 0.55 : 1,
                child: rows.isEmpty
                    ? const StateCard(
                        child: EmptyState(
                          icon: Icons.leaderboard_rounded,
                          title: 'Belum ada data KPI',
                        ),
                      )
                    : _Content(rows: rows),
              )
            else if (async.hasError)
              StateCard(
                child: ErrorState(
                  message: 'Gagal memuat ringkasan KPI.',
                  onRetry: () => ref.invalidate(kpiOverviewProvider(period)),
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

class _Content extends StatelessWidget {
  const _Content({required this.rows});

  final List<KpiOverviewRow> rows;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final scored = rows.where((r) => r.kpi.compositeScore != null).toList();
    final average = scored.isEmpty
        ? null
        : scored.fold<double>(0, (s, r) => s + r.kpi.compositeScore!) /
              scored.length;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.all(AppSpacing.md),
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
            border: Border.all(color: AppColors.outline.withValues(alpha: 0.3)),
          ),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Rata-rata skor',
                      style: textTheme.bodySmall?.copyWith(
                        color: AppColors.onSurfaceVariant,
                      ),
                    ),
                    Text(
                      formatScore(average),
                      style: textTheme.headlineMedium?.copyWith(
                        fontWeight: FontWeight.w800,
                        color: average == null
                            ? AppColors.onSurfaceVariant
                            : scoreColor(average),
                      ),
                    ),
                  ],
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    'Sudah dinilai',
                    style: textTheme.bodySmall?.copyWith(
                      color: AppColors.onSurfaceVariant,
                    ),
                  ),
                  Text(
                    '${scored.length} dari ${rows.length} worker',
                    style: textTheme.titleSmall,
                  ),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: AppSpacing.md),
        Container(
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
                for (var i = 0; i < rows.length; i++) ...[
                  if (i > 0)
                    Divider(
                      height: 1,
                      indent: AppSpacing.md,
                      endIndent: AppSpacing.md,
                      color: AppColors.outline.withValues(alpha: 0.2),
                    ),
                  _OverviewRow(rank: i + 1, row: rows[i]),
                ],
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _OverviewRow extends StatelessWidget {
  const _OverviewRow({required this.rank, required this.row});

  final int rank;
  final KpiOverviewRow row;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final composite = row.kpi.compositeScore;
    final color = composite == null
        ? AppColors.onSurfaceVariant
        : scoreColor(composite);

    return InkWell(
      onTap: () => context.push(RoutePaths.ownerWorkerDetailFor(row.worker.id)),
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.md,
          vertical: AppSpacing.sm + 4,
        ),
        child: Row(
          children: [
            SizedBox(
              width: 24,
              child: Text(
                composite == null ? '-' : '$rank',
                style: textTheme.titleSmall?.copyWith(
                  color: AppColors.onSurfaceVariant,
                ),
              ),
            ),
            WorkerAvatar(
              name: row.worker.fullName,
              avatarUrl: row.worker.avatarUrl,
              radius: 20,
            ),
            const SizedBox(width: AppSpacing.sm + 4),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    row.worker.fullName,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: textTheme.titleSmall,
                  ),
                  Text(
                    '${row.worker.division} · ${row.kpi.totalOrdersHandled} order · '
                    'rating ${formatRating(row.kpi.avgRating)}',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: textTheme.bodySmall?.copyWith(
                      color: AppColors.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: AppSpacing.sm),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.14),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                composite == null ? 'Belum dinilai' : formatScore(composite),
                style: textTheme.labelMedium?.copyWith(
                  color: composite == null ? AppColors.onSurfaceVariant : AppColors.onSurface,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
