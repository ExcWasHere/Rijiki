import 'package:rijiki/features/worker_management/domain/kpi.dart';
import 'package:rijiki/features/worker_management/domain/worker_input.dart';
import 'package:rijiki/features/worker_management/domain/worker_profile.dart';
import 'package:rijiki/features/worker_management/domain/worker_review.dart';

abstract interface class WorkerRepository {
  Future<List<WorkerSummary>> fetchWorkers();
  Future<WorkerProfile> createWorker(WorkerInput input);
  Future<WorkerProfile> updateWorker(String id, WorkerInput input);
  Future<List<WorkerReview>> fetchReviews(String workerId);
  Future<WorkerKpi> fetchKpi(String workerId, KpiPeriod period);
  Future<List<WorkerKpi>> fetchKpiOverview(KpiPeriod period);
  Future<WorkerKpi> saveAssessment({
    required String workerId,
    required KpiPeriod period,
    required Map<KpiAspect, int> scores,
    String? note,
  });
}
