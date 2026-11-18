import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:rijiki/core/theme/app_colors.dart';
import 'package:rijiki/core/theme/app_spacing.dart';
import 'package:rijiki/features/worker_management/domain/kpi.dart';
import 'package:rijiki/features/worker_management/domain/worker_profile.dart';
import 'package:rijiki/features/worker_management/presentation/controllers/worker_kpi_controller.dart';
import 'package:rijiki/features/worker_management/presentation/controllers/worker_list_controller.dart';
import 'package:rijiki/features/worker_management/presentation/utils/worker_format.dart';
import 'package:rijiki/features/worker_management/presentation/widgets/kpi_aspect_selector.dart';
import 'package:rijiki/features/worker_management/presentation/widgets/kpi_score_card.dart';
import 'package:rijiki/features/worker_management/presentation/widgets/worker_avatar.dart';
import 'package:rijiki/shared/widgets/error_state.dart';
import 'package:rijiki/shared/widgets/loading_skeleton.dart';
import 'package:rijiki/shared/widgets/state_card.dart';

class KpiAssessmentPage extends ConsumerWidget {
  const KpiAssessmentPage({
    super.key,
    required this.workerId,
    required this.period,
  });

  final String workerId;
  final KpiPeriod period;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final worker = ref.watch(workerSummaryProvider(workerId))?.profile;
    final async = ref.watch(
      workerKpiProvider((workerId: workerId, period: period)),
    );
    final kpi = async.value;

    Widget body;
    if (worker != null && kpi != null) {
      body = _AssessmentForm(
        key: ValueKey('${worker.id}-${period.year}-${period.month}'),
        worker: worker,
        kpi: kpi,
      );
    } else if (async.hasError) {
      body = Padding(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: StateCard(
          child: ErrorState(
            message: 'Gagal memuat penilaian.',
            onRetry: () => ref.invalidate(workerKpiProvider),
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
        title: Text(period.isCurrent ? 'Penilaian KPI' : 'Lihat penilaian'),
      ),
      body: body,
    );
  }
}

class _AssessmentForm extends ConsumerStatefulWidget {
  const _AssessmentForm({super.key, required this.worker, required this.kpi});

  final WorkerProfile worker;
  final WorkerKpi kpi;

  @override
  ConsumerState<_AssessmentForm> createState() => _AssessmentFormState();
}

class _AssessmentFormState extends ConsumerState<_AssessmentForm> {
  late final Map<KpiAspect, int?> _scores;
  late final TextEditingController _note;

  bool get _editable => widget.kpi.period.isCurrent;

  @override
  void initState() {
    super.initState();
    final existing = widget.kpi.assessment;
    _scores = {
      for (final aspect in KpiAspect.values) aspect: existing?.scores[aspect],
    };
    _note = TextEditingController(text: existing?.note ?? '');
  }

  @override
  void dispose() {
    _note.dispose();
    super.dispose();
  }

  int get _answered => _scores.values.where((v) => v != null).length;
  bool get _complete => _answered == KpiAspect.values.length;

  double? get _preview {
    if (!_complete) return null;
    final total = _scores.values.fold<int>(0, (sum, v) => sum + v!);
    return total / (KpiAspect.values.length * 5) * 100;
  }

  Future<void> _save() async {
    if (!_complete) return;
    FocusScope.of(context).unfocus();

    final messenger = ScaffoldMessenger.of(context);
    final router = GoRouter.of(context);

    final ok = await ref
        .read(assessmentProvider.notifier)
        .save(
          workerId: widget.worker.id,
          period: widget.kpi.period,
          scores: {for (final e in _scores.entries) e.key: e.value!},
          note: _note.text,
        );
    if (!mounted) return;

    final message = ok
        ? 'Penilaian ${widget.worker.fullName} disimpan.'
        : (ref.read(assessmentProvider).errorMessage ?? 'Gagal menyimpan.');
    messenger
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(message)));
    if (ok) router.pop();
  }

  @override
  Widget build(BuildContext context) {
    final saving = ref.watch(assessmentProvider).saving;
    final textTheme = Theme.of(context).textTheme;
    final preview = _preview;
    final color = preview == null
        ? AppColors.onSurfaceVariant
        : scoreColor(preview);

    return ListView(
      keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.lg,
        AppSpacing.md,
        AppSpacing.lg,
        AppSpacing.xl,
      ),
      children: [
        Row(
          children: [
            WorkerAvatar(
              name: widget.worker.fullName,
              avatarUrl: widget.worker.avatarUrl,
            ),
            const SizedBox(width: AppSpacing.md),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(widget.worker.fullName, style: textTheme.titleMedium),
                  Text(
                    '${widget.worker.employeeCode} · ${widget.worker.division}',
                    style: textTheme.bodySmall?.copyWith(
                      color: AppColors.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.md),
        Container(
          padding: const EdgeInsets.all(AppSpacing.md),
          decoration: BoxDecoration(
            color: AppColors.primary.withValues(alpha: 0.18),
            borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
          ),
          child: Row(
            children: [
              const Icon(Icons.calendar_month_rounded, color: AppColors.primaryDark),
              const SizedBox(width: AppSpacing.sm + 4),
              Expanded(
                child: Text(
                  _editable
                      ? 'Periode ${formatPeriod(widget.kpi.period)}. Bisa diubah '
                            'selama bulan ini berjalan.'
                      : 'Periode ${formatPeriod(widget.kpi.period)}. Penilaian '
                            'bulan yang sudah lewat hanya bisa dilihat.',
                  style: textTheme.bodySmall,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: AppSpacing.md),
        for (final aspect in KpiAspect.values) ...[
          Container(
            padding: const EdgeInsets.all(AppSpacing.md),
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
              border: Border.all(color: AppColors.outline.withValues(alpha: 0.3)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(aspect.label, style: textTheme.titleSmall),
                const SizedBox(height: 2),
                Text(
                  aspect.description,
                  style: textTheme.bodySmall?.copyWith(
                    color: AppColors.onSurfaceVariant,
                  ),
                ),
                const SizedBox(height: AppSpacing.sm + 4),
                KpiAspectSelector(
                  value: _scores[aspect],
                  onChanged: (_editable && !saving)
                      ? (score) => setState(() => _scores[aspect] = score)
                      : null,
                ),
                const SizedBox(height: 6),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      '1 = kurang',
                      style: textTheme.labelSmall?.copyWith(
                        color: AppColors.onSurfaceVariant,
                      ),
                    ),
                    Text(
                      '5 = sangat baik',
                      style: textTheme.labelSmall?.copyWith(
                        color: AppColors.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.sm + 4),
        ],
        TextField(
          controller: _note,
          enabled: _editable && !saving,
          minLines: 2,
          maxLines: 4,
          maxLength: 300,
          textCapitalization: TextCapitalization.sentences,
          decoration: const InputDecoration(
            labelText: 'Catatan Owner (opsional)',
            alignLabelWithHint: true,
          ),
        ),
        const SizedBox(height: AppSpacing.sm),
        Container(
          padding: const EdgeInsets.all(AppSpacing.md),
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
            border: Border.all(color: color.withValues(alpha: 0.5)),
          ),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Skor operasional', style: textTheme.titleSmall),
                    Text(
                      preview == null
                          ? '$_answered dari ${KpiAspect.values.length} aspek dinilai'
                          : ScoreBand.of(preview).label,
                      style: textTheme.bodySmall?.copyWith(
                        color: AppColors.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
              Text(
                formatScore(preview),
                style: textTheme.headlineMedium?.copyWith(
                  color: color,
                  fontWeight: FontWeight.w800,
                ),
              ),
              Text(
                ' / 100',
                style: textTheme.bodyMedium?.copyWith(
                  color: AppColors.onSurfaceVariant,
                ),
              ),
            ],
          ),
        ),
        if (_editable) ...[
          const SizedBox(height: AppSpacing.lg),
          FilledButton(
            onPressed: (_complete && !saving) ? _save : null,
            child: saving
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: AppColors.onPrimary,
                    ),
                  )
                : const Text('Simpan penilaian'),
          ),
          if (!_complete)
            Padding(
              padding: const EdgeInsets.only(top: AppSpacing.sm),
              child: Text(
                'Nilai keempat aspek dulu untuk menyimpan.',
                textAlign: TextAlign.center,
                style: textTheme.bodySmall?.copyWith(
                  color: AppColors.onSurfaceVariant,
                ),
              ),
            ),
        ],
      ],
    );
  }
}
