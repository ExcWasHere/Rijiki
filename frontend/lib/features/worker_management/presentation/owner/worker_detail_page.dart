import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:rijiki/app/router/route_paths.dart';
import 'package:rijiki/core/enums/user_role.dart';
import 'package:rijiki/core/session/session_provider.dart';
import 'package:rijiki/core/theme/app_colors.dart';
import 'package:rijiki/core/theme/app_spacing.dart';
import 'package:rijiki/core/utils/date_format.dart';
import 'package:rijiki/features/access_control/presentation/controllers/worker_permission_controller.dart';
import 'package:rijiki/features/worker_management/domain/worker_profile.dart';
import 'package:rijiki/features/worker_management/domain/worker_review.dart';
import 'package:rijiki/features/worker_management/presentation/controllers/worker_kpi_controller.dart';
import 'package:rijiki/features/worker_management/presentation/controllers/worker_list_controller.dart';
import 'package:rijiki/features/worker_management/presentation/utils/worker_format.dart';
import 'package:rijiki/features/worker_management/presentation/widgets/kpi_period_picker.dart';
import 'package:rijiki/features/worker_management/presentation/widgets/kpi_score_card.dart';
import 'package:rijiki/features/worker_management/presentation/widgets/rating_summary_card.dart';
import 'package:rijiki/features/worker_management/presentation/widgets/review_tile.dart';
import 'package:rijiki/features/worker_management/presentation/widgets/worker_avatar.dart';
import 'package:rijiki/shared/widgets/empty_state.dart';
import 'package:rijiki/shared/widgets/error_state.dart';
import 'package:rijiki/shared/widgets/loading_skeleton.dart';
import 'package:rijiki/shared/widgets/state_card.dart';

class WorkerDetailPage extends ConsumerWidget {
  const WorkerDetailPage({super.key, required this.workerId});

  final String workerId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(workersProvider);
    final summary = ref.watch(workerSummaryProvider(workerId));

    Widget body;
    if (summary != null) {
      body = _Body(summary: summary);
    } else if (async.hasError) {
      body = Padding(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: StateCard(
          child: ErrorState(
            message: 'Gagal memuat data worker.',
            onRetry: () => ref.invalidate(workersProvider),
          ),
        ),
      );
    } else if (async.hasValue) {
      body = Padding(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: StateCard(
          child: EmptyState(
            icon: Icons.search_off_rounded,
            title: 'Worker tidak ditemukan',
            actionLabel: 'Kembali',
            onAction: () => context.pop(),
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
        title: const Text('Detail worker'),
        actions: [
          if (summary != null)
            IconButton(
              tooltip: 'Ubah data worker',
              icon: const Icon(Icons.edit_outlined),
              onPressed: () =>
                  context.push(RoutePaths.ownerWorkerEditFor(workerId)),
            ),
        ],
      ),
      body: body,
    );
  }
}

class _Body extends ConsumerWidget {
  const _Body({required this.summary});

  final WorkerSummary summary;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final worker = summary.profile;
    final isOwner = ref.watch(sessionProvider)?.role == UserRole.owner;

    return RefreshIndicator(
      color: AppColors.primaryDark,
      onRefresh: () async {
        ref.invalidate(workersProvider);
        ref.invalidate(workerReviewsProvider(worker.id));
        ref.invalidate(workerKpiProvider);
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
          _ProfileCard(worker: worker),
          const SizedBox(height: AppSpacing.lg),
          _SectionTitle('KPI'),
          _KpiSection(worker: worker),
          const SizedBox(height: AppSpacing.lg),
          _SectionTitle('Rating dari customer'),
          _RatingSection(workerId: worker.id),
          if (isOwner) ...[
            const SizedBox(height: AppSpacing.lg),
            _SectionTitle('Hak akses'),
            _AccessTile(workerId: worker.id),
          ],
        ],
      ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  const _SectionTitle(this.title);

  final String title;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(left: AppSpacing.xs, bottom: AppSpacing.sm),
      child: Text(title, style: Theme.of(context).textTheme.titleMedium),
    );
  }
}

class _ProfileCard extends StatelessWidget {
  const _ProfileCard({required this.worker});

  final WorkerProfile worker;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
        border: Border.all(color: AppColors.outline.withValues(alpha: 0.3)),
      ),
      child: Column(
        children: [
          Row(
            children: [
              WorkerAvatar(
                name: worker.fullName,
                avatarUrl: worker.avatarUrl,
                radius: 32,
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(worker.fullName, style: textTheme.titleLarge),
                    const SizedBox(height: 4),
                    Wrap(
                      spacing: 6,
                      runSpacing: 4,
                      children: [
                        _Chip(
                          text: worker.employeeCode,
                          color: AppColors.primaryDark,
                        ),
                        _Chip(
                          text: worker.division,
                          color: AppColors.rijikiOrange,
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          const Divider(),
          _InfoRow(icon: Icons.mail_outline_rounded, text: worker.email),
          _InfoRow(icon: Icons.phone_outlined, text: worker.phoneNumber),
          _InfoRow(
            icon: Icons.event_available_outlined,
            text:
                'Bergabung ${formatDate(worker.joinDate)} · '
                '${formatTenure(worker.joinDate)}',
          ),
        ],
      ),
    );
  }
}

class _Chip extends StatelessWidget {
  const _Chip({required this.text, required this.color});

  final String text;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        text,
        style: Theme.of(context).textTheme.labelSmall?.copyWith(
          color: AppColors.onSurface,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  const _InfoRow({required this.icon, required this.text});

  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: AppSpacing.sm + 2),
      child: Row(
        children: [
          Icon(icon, size: AppSpacing.iconSm + 2, color: AppColors.onSurfaceVariant),
          const SizedBox(width: AppSpacing.sm + 4),
          Expanded(
            child: Text(text, style: Theme.of(context).textTheme.bodyMedium),
          ),
        ],
      ),
    );
  }
}

class _KpiSection extends ConsumerWidget {
  const _KpiSection({required this.worker});

  final WorkerProfile worker;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final period = ref.watch(kpiPeriodProvider);
    final notifier = ref.read(kpiPeriodProvider.notifier);
    final async = ref.watch(workerKpiProvider((workerId: worker.id, period: period)));
    final kpi = async.value;
    final textTheme = Theme.of(context).textTheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        KpiPeriodPicker(
          period: period,
          onPrevious: notifier.previous,
          onNext: notifier.next,
        ),
        const SizedBox(height: AppSpacing.sm + 4),
        if (kpi != null) ...[
          AnimatedOpacity(
            duration: const Duration(milliseconds: 200),
            opacity: async.isLoading ? 0.55 : 1,
            child: KpiScoreCard(kpi: kpi),
          ),
          if (kpi.assessment?.note != null) ...[
            const SizedBox(height: AppSpacing.sm + 4),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(AppSpacing.md),
              decoration: BoxDecoration(
                color: AppColors.primary.withValues(alpha: 0.14),
                borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
              ),
              child: Text(
                'Catatan Owner: ${kpi.assessment!.note}',
                style: textTheme.bodyMedium,
              ),
            ),
          ],
          const SizedBox(height: AppSpacing.sm + 4),
          OutlinedButton.icon(
            onPressed: () => context.push(
              RoutePaths.ownerWorkerKpiAssessFor(
                worker.id,
                period.month,
                period.year,
              ),
            ),
            icon: Icon(
              period.isCurrent
                  ? Icons.rate_review_outlined
                  : Icons.visibility_outlined,
              size: AppSpacing.iconSm + 2,
            ),
            label: Text(
              !period.isCurrent
                  ? 'Lihat penilaian'
                  : (kpi.assessment == null
                        ? 'Beri penilaian KPI'
                        : 'Ubah penilaian KPI'),
            ),
          ),
        ] else if (async.hasError)
          StateCard(
            child: ErrorState(
              message: 'Gagal memuat KPI.',
              onRetry: () => ref.invalidate(workerKpiProvider),
            ),
          )
        else
          const LoadingSkeleton(height: 200, radius: AppSpacing.radiusLg),
      ],
    );
  }
}

class _RatingSection extends ConsumerStatefulWidget {
  const _RatingSection({required this.workerId});

  final String workerId;

  @override
  ConsumerState<_RatingSection> createState() => _RatingSectionState();
}

class _RatingSectionState extends ConsumerState<_RatingSection> {
  static const int _collapsed = 5;
  bool _showAll = false;

  @override
  Widget build(BuildContext context) {
    final async = ref.watch(workerReviewsProvider(widget.workerId));
    final reviews = async.value;

    if (reviews == null) {
      return async.hasError
          ? StateCard(
              child: ErrorState(
                message: 'Gagal memuat rating.',
                onRetry: () =>
                    ref.invalidate(workerReviewsProvider(widget.workerId)),
              ),
            )
          : const LoadingSkeleton(height: 180, radius: AppSpacing.radiusLg);
    }
    if (reviews.isEmpty) {
      return const StateCard(
        child: EmptyState(
          icon: Icons.star_outline_rounded,
          title: 'Belum ada rating',
          message: 'Rating muncul setelah customer menilai order yang ditangani.',
        ),
      );
    }

    final shown = _showAll ? reviews : reviews.take(_collapsed).toList();

    return Column(
      children: [
        RatingSummaryCard(summary: RatingSummary.from(reviews)),
        const SizedBox(height: AppSpacing.sm + 4),
        Container(
          clipBehavior: Clip.antiAlias,
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
            border: Border.all(color: AppColors.outline.withValues(alpha: 0.3)),
          ),
          child: Column(
            children: [
              for (var i = 0; i < shown.length; i++) ...[
                if (i > 0)
                  Divider(
                    height: 1,
                    indent: AppSpacing.md,
                    endIndent: AppSpacing.md,
                    color: AppColors.outline.withValues(alpha: 0.2),
                  ),
                ReviewTile(review: shown[i]),
              ],
              if (reviews.length > _collapsed) ...[
                Divider(
                  height: 1,
                  color: AppColors.outline.withValues(alpha: 0.2),
                ),
                TextButton(
                  onPressed: () => setState(() => _showAll = !_showAll),
                  child: Text(
                    _showAll
                        ? 'Tampilkan lebih sedikit'
                        : 'Tampilkan semua (${reviews.length})',
                  ),
                ),
              ],
            ],
          ),
        ),
      ],
    );
  }
}

class _AccessTile extends ConsumerWidget {
  const _AccessTile({required this.workerId});

  final String workerId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final textTheme = Theme.of(context).textTheme;
    final permissions = ref.watch(workerPermissionsProvider(workerId));
    final subtitle = permissions.when(
      data: (list) => list.isEmpty
          ? 'Belum ada izin tambahan'
          : '${list.length} izin aktif',
      loading: () => 'Memuat...',
      error: (_, _) => 'Gagal memuat izin',
    );

    return Material(
      color: AppColors.surface,
      borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
      child: InkWell(
        borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
        onTap: () => context.push(RoutePaths.ownerWorkerAccessFor(workerId)),
        child: Ink(
          padding: const EdgeInsets.all(AppSpacing.md),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
            border: Border.all(color: AppColors.outline.withValues(alpha: 0.3)),
          ),
          child: Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: AppColors.primaryDark.withValues(alpha: 0.14),
                  borderRadius: BorderRadius.circular(AppSpacing.radiusMd - 2),
                ),
                child: const Icon(
                  Icons.admin_panel_settings_rounded,
                  color: AppColors.primaryDark,
                ),
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Atur hak akses', style: textTheme.titleSmall),
                    Text(
                      subtitle,
                      style: textTheme.bodySmall?.copyWith(
                        color: AppColors.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
              const Icon(
                Icons.chevron_right_rounded,
                color: AppColors.onSurfaceVariant,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
