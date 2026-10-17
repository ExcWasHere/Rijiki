import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:rijiki/app/providers.dart';
import 'package:rijiki/features/worker_management/domain/kpi.dart';
import 'package:rijiki/features/worker_management/domain/worker_profile.dart';
import 'package:rijiki/features/worker_management/domain/worker_review.dart';
import 'package:rijiki/features/worker_management/presentation/controllers/worker_list_controller.dart';

class KpiPeriodNotifier extends Notifier<KpiPeriod> {
  @override
  KpiPeriod build() => KpiPeriod.current();

  void previous() => state = state.previous;

  void next() {
    if (!state.isCurrent) state = state.next;
  }
}

final kpiPeriodProvider =
    NotifierProvider.autoDispose<KpiPeriodNotifier, KpiPeriod>(
      KpiPeriodNotifier.new,
    );

typedef WorkerKpiKey = ({String workerId, KpiPeriod period});

final workerKpiProvider = FutureProvider.autoDispose
    .family<WorkerKpi, WorkerKpiKey>((ref, key) {
      return ref
          .watch(workerRepositoryProvider)
          .fetchKpi(key.workerId, key.period);
    });

final workerReviewsProvider = FutureProvider.autoDispose
    .family<List<WorkerReview>, String>((ref, workerId) {
      return ref.watch(workerRepositoryProvider).fetchReviews(workerId);
    });

@immutable
class KpiOverviewRow {
  const KpiOverviewRow({required this.worker, required this.kpi});

  final WorkerProfile worker;
  final WorkerKpi kpi;
}

final kpiOverviewProvider = FutureProvider.autoDispose
    .family<List<KpiOverviewRow>, KpiPeriod>((ref, period) async {
      final repository = ref.watch(workerRepositoryProvider);
      final workers = await ref.watch(workersProvider.future);
      final kpis = await repository.fetchKpiOverview(period);

      final byWorker = {for (final k in kpis) k.workerId: k};
      final rows = [
        for (final summary in workers)
          if (byWorker[summary.profile.id] != null)
            KpiOverviewRow(
              worker: summary.profile,
              kpi: byWorker[summary.profile.id]!,
            ),
      ]..sort((a, b) {
          final x = a.kpi.compositeScore;
          final y = b.kpi.compositeScore;
          if (x == null && y == null) return 0;
          if (x == null) return 1;
          if (y == null) return -1;
          return y.compareTo(x);
        });
      return rows;
    });

@immutable
class AssessmentFormState {
  const AssessmentFormState({this.saving = false, this.errorMessage});

  final bool saving;
  final String? errorMessage;
}

class AssessmentNotifier extends Notifier<AssessmentFormState> {
  @override
  AssessmentFormState build() => const AssessmentFormState();
  Future<bool> save({
    required String workerId,
    required KpiPeriod period,
    required Map<KpiAspect, int> scores,
    String? note,
  }) async {
    if (state.saving) return false;
    state = const AssessmentFormState(saving: true);
    try {
      await ref
          .read(workerRepositoryProvider)
          .saveAssessment(
            workerId: workerId,
            period: period,
            scores: scores,
            note: note,
          );
      if (!ref.mounted) return true;
      ref.invalidate(workerKpiProvider((workerId: workerId, period: period)));
      ref.invalidate(kpiOverviewProvider(period));
      state = const AssessmentFormState();
      return true;
    } catch (_) {
      if (!ref.mounted) return false;
      state = const AssessmentFormState(
        errorMessage: 'Gagal menyimpan penilaian. Coba lagi ya.',
      );
      return false;
    }
  }
}

final assessmentProvider =
    NotifierProvider.autoDispose<AssessmentNotifier, AssessmentFormState>(
      AssessmentNotifier.new,
    );
