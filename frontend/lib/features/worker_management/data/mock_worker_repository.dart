import 'package:rijiki/core/mock/mock_scenario.dart';
import 'package:rijiki/features/worker_management/domain/kpi.dart';
import 'package:rijiki/features/worker_management/domain/worker_input.dart';
import 'package:rijiki/features/worker_management/domain/worker_profile.dart';
import 'package:rijiki/features/worker_management/domain/worker_repository.dart';
import 'package:rijiki/features/worker_management/domain/worker_review.dart';

class MockWorkerRepository implements WorkerRepository {
  MockWorkerRepository({this.scenario = MockScenario.data});

  final MockScenario scenario;

  static const Duration _writeLatency = Duration(milliseconds: 450);

  late final List<WorkerProfile> _workers = _seedWorkers();
  late final Map<String, List<WorkerReview>> _reviews = _seedReviews();
  late final Map<String, KpiAssessment> _assessments = _seedAssessments();

  @override
  Future<List<WorkerSummary>> fetchWorkers() {
    return scenario.resolve<List<WorkerSummary>>(
      empty: const [],
      data: [
        for (final worker in _workers)
          () {
            final reviews = _reviews[worker.id] ?? const [];
            final summary = RatingSummary.from(reviews);
            return WorkerSummary(
              profile: worker,
              avgRating: summary.average,
              ratingCount: summary.count,
            );
          }(),
      ],
    );
  }

  @override
  Future<WorkerProfile> createWorker(WorkerInput input) async {
    await _write();
    final worker = _fromInput(
      'wrk-${DateTime.now().microsecondsSinceEpoch}',
      input,
    );
    _workers.add(worker);
    return worker;
  }

  @override
  Future<WorkerProfile> updateWorker(String id, WorkerInput input) async {
    await _write();
    final index = _workers.indexWhere((w) => w.id == id);
    if (index == -1) throw const MockException('Worker tidak ditemukan');
    final updated = _fromInput(id, input, email: _workers[index].email);
    _workers[index] = updated;
    return updated;
  }

  @override
  Future<List<WorkerReview>> fetchReviews(String workerId) {
    final reviews = [...(_reviews[workerId] ?? const <WorkerReview>[])]
      ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
    return scenario.resolve<List<WorkerReview>>(empty: const [], data: reviews);
  }

  @override
  Future<WorkerKpi> fetchKpi(String workerId, KpiPeriod period) {
    return scenario.resolve<WorkerKpi>(
      empty: _emptyKpi(workerId, period),
      data: _kpiFor(workerId, period),
    );
  }

  @override
  Future<List<WorkerKpi>> fetchKpiOverview(KpiPeriod period) {
    return scenario.resolve<List<WorkerKpi>>(
      empty: const [],
      data: [for (final worker in _workers) _kpiFor(worker.id, period)],
    );
  }

  @override
  Future<WorkerKpi> saveAssessment({
    required String workerId,
    required KpiPeriod period,
    required Map<KpiAspect, int> scores,
    String? note,
  }) async {
    await _write();
    if (!period.isCurrent) {
      throw const MockException(
        'Penilaian hanya bisa diubah pada bulan berjalan.',
      );
    }
    final trimmed = note?.trim() ?? '';
    _assessments[_key(workerId, period)] = KpiAssessment(
      scores: Map.of(scores),
      note: trimmed.isEmpty ? null : trimmed,
      updatedAt: DateTime.now(),
    );
    return _kpiFor(workerId, period);
  }

  Future<void> _write() async {
    await Future<void>.delayed(_writeLatency);
    if (scenario == MockScenario.error) throw const MockException();
  }

  static String _key(String workerId, KpiPeriod p) =>
      '$workerId|${p.year}-${p.month}';

  static WorkerKpi _emptyKpi(String workerId, KpiPeriod period) =>
      WorkerKpi(workerId: workerId, period: period, totalOrdersHandled: 0);

  static WorkerProfile _fromInput(
    String id,
    WorkerInput input, {
    String? email,
  }) {
    return WorkerProfile(
      id: id,
      fullName: input.fullName.trim(),
      email: email ?? input.email.trim(),
      phoneNumber: input.phoneNumber.trim(),
      employeeCode: input.employeeCode.trim().toUpperCase(),
      division: input.division.trim(),
      joinDate: input.joinDate,
    );
  }

  WorkerKpi _kpiFor(String workerId, KpiPeriod period) {
    final index = _workers.indexWhere((w) => w.id == workerId);
    final seed = (index < 0 ? 0 : index) * 7 + period.month * 3 + period.year;

    final reviews = (_reviews[workerId] ?? const <WorkerReview>[]).where(
      (r) =>
          r.createdAt.month == period.month && r.createdAt.year == period.year,
    );
    final avg = reviews.isEmpty
        ? null
        : reviews.fold<int>(0, (s, r) => s + r.ratingValue) / reviews.length;

    return WorkerKpi(
      workerId: workerId,
      period: period,
      totalOrdersHandled: 18 + seed % 35,
      avgRating: avg,
      onTimeCompletionPct: 82 + (seed % 17).toDouble(),
      assessment: _assessments[_key(workerId, period)],
    );
  }

  static List<WorkerProfile> _seedWorkers() {
    return [
      WorkerProfile(
        id: 'wrk-1',
        fullName: 'Budi Santoso',
        email: 'budi.santoso@rijiki.id',
        phoneNumber: '081234560001',
        employeeCode: 'RJK-W001',
        division: 'Cleaning',
        joinDate: DateTime(2024, 2, 5),
      ),
      WorkerProfile(
        id: 'wrk-2',
        fullName: 'Siti Rahmawati',
        email: 'siti.rahmawati@rijiki.id',
        phoneNumber: '081234560002',
        employeeCode: 'RJK-W002',
        division: 'Cleaning',
        joinDate: DateTime(2024, 6, 17),
      ),
      WorkerProfile(
        id: 'wrk-3',
        fullName: 'Andi Pratama',
        email: 'andi.pratama@rijiki.id',
        phoneNumber: '081234560003',
        employeeCode: 'RJK-W003',
        division: 'Pickup-Delivery',
        joinDate: DateTime(2024, 9, 2),
      ),
      WorkerProfile(
        id: 'wrk-4',
        fullName: 'Dewi Anggraini',
        email: 'dewi.anggraini@rijiki.id',
        phoneNumber: '081234560004',
        employeeCode: 'RJK-W004',
        division: 'Reparasi',
        joinDate: DateTime(2025, 1, 13),
      ),
      WorkerProfile(
        id: 'wrk-5',
        fullName: 'Rizky Hidayat',
        email: 'rizky.hidayat@rijiki.id',
        phoneNumber: '081234560005',
        employeeCode: 'RJK-W005',
        division: 'Pickup-Delivery',
        joinDate: DateTime(2025, 5, 26),
      ),
      WorkerProfile(
        id: 'wrk-6',
        fullName: 'Nadia Putri',
        email: 'nadia.putri@rijiki.id',
        phoneNumber: '081234560006',
        employeeCode: 'RJK-W006',
        division: 'Cleaning',
        joinDate: DateTime(2025, 8, 11),
      ),
    ];
  }

  static Map<String, List<WorkerReview>> _seedReviews() {
    final now = DateTime.now();
    const names = [
      'Rina A.',
      'Dimas P.',
      'Salsa M.',
      'Fajar R.',
      'Citra L.',
      'Yoga S.',
      'Anisa K.',
      'Bagas T.',
    ];
    const services = [
      'Deep Clean',
      'Fast Clean',
      'Reguler Treatment',
      'Glue Repair',
      'Unyellowing',
    ];
    const stars = [5, 5, 4, 5, 3, 5, 4, 5, 5, 4, 5, 2];
    const comments = [
      'Sepatuku bersih banget, rapi dan wangi.',
      'Pengerjaan cepat dan sesuai estimasi.',
      'Hasilnya bagus, tapi sedikit telat dari jadwal.',
      'Ramah dan komunikatif, sepatu kembali seperti baru.',
      'Cukup bersih, masih ada noda kecil di bagian sol.',
      null,
      'Pickup tepat waktu, kurirnya sopan.',
      'Mantap, bakal order lagi.',
    ];

    final result = <String, List<WorkerReview>>{};
    for (var w = 0; w < 6; w++) {
      final reviews = <WorkerReview>[];
      for (var k = 0; k < 12; k++) {
        final star = stars[(k + w) % stars.length];
        reviews.add(
          WorkerReview(
            id: 'rv-$w-$k',
            customerName: names[(k + w) % names.length],
            ratingValue: star,
            createdAt: now.subtract(Duration(days: k * 6 + w + 1)),
            orderNumber: 'RJK-${1000 + w * 40 + k}',
            serviceName: services[(k + w) % services.length],
            comment: comments[(k * 3 + w) % comments.length],
          ),
        );
      }
      result['wrk-${w + 1}'] = reviews;
    }
    return result;
  }

  static Map<String, KpiAssessment> _seedAssessments() {
    final last = KpiPeriod.current().previous;
    KpiAssessment make(List<int> scores, String? note) => KpiAssessment(
      scores: {
        for (var i = 0; i < KpiAspect.values.length; i++)
          KpiAspect.values[i]: scores[i],
      },
      note: note,
      updatedAt: DateTime(last.year, last.month, 28),
    );

    return {
      _key('wrk-1', last): make([5, 4, 5, 4], 'Konsisten dan rapi.'),
      _key('wrk-2', last): make([4, 4, 4, 5], null),
      _key('wrk-3', last): make([4, 5, 3, 4], 'Perlu lebih rapi saat serah terima.'),
    };
  }
}
