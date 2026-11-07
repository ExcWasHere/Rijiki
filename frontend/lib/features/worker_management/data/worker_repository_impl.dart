import 'package:rijiki/core/constants/app_strings.dart';
import 'package:rijiki/core/error/app_exception.dart';
import 'package:rijiki/core/error/failure.dart';
import 'package:rijiki/core/network/api_client.dart';
import 'package:rijiki/core/network/api_endpoint.dart';
import 'package:rijiki/features/worker_management/domain/kpi.dart';
import 'package:rijiki/features/worker_management/domain/worker_input.dart';
import 'package:rijiki/features/worker_management/domain/worker_profile.dart';
import 'package:rijiki/features/worker_management/domain/worker_repository.dart';
import 'package:rijiki/features/worker_management/domain/worker_review.dart';

/// Data karyawan dari backend: daftar, tambah, ubah, ulasan, KPI, dan penilaian.
///
/// Catatan: `onTimeCompletionPct` selalu kosong karena definisi "tepat waktu"
/// belum ditetapkan di PRD (formula KPI: TBD dengan Rijiki).
class WorkerRepositoryImpl implements WorkerRepository {
  WorkerRepositoryImpl({required this.api});

  final ApiClient api;

  @override
  Future<List<WorkerSummary>> fetchWorkers() => _guard(() async {
    final json = await api.get('${ApiEndpoints.workers}/manage', auth: true);
    final raw = json['items'] as List<dynamic>? ?? const [];
    return [
      for (final item in raw) _summaryFromJson(item as Map<String, dynamic>),
    ];
  });

  @override
  Future<WorkerProfile> createWorker(WorkerInput input) => _guard(() async {
    final json = await api.post(
      ApiEndpoints.workers,
      auth: true,
      body: _bodyOf(input),
    );
    return _profileFromJson(json);
  });

  @override
  Future<WorkerProfile> updateWorker(String id, WorkerInput input) =>
      _guard(() async {
        final json = await api.patch(
          '${ApiEndpoints.workers}/$id',
          auth: true,
          body: _bodyOf(input),
        );
        return _profileFromJson(json);
      });

  @override
  Future<List<WorkerReview>> fetchReviews(String workerId) => _guard(() async {
    final json = await api.get(ApiEndpoints.workerReviews(workerId), auth: true);
    final raw = json['items'] as List<dynamic>? ?? const [];
    return [
      for (final item in raw) _reviewFromJson(item as Map<String, dynamic>),
    ];
  });

  @override
  Future<WorkerKpi> fetchKpi(String workerId, KpiPeriod period) =>
      _guard(() async {
        final path = Uri(
          path: ApiEndpoints.workerKpi(workerId),
          queryParameters: _periodQuery(period),
        ).toString();
        return _kpiFromJson(await api.get(path, auth: true));
      });

  @override
  Future<List<WorkerKpi>> fetchKpiOverview(KpiPeriod period) =>
      _guard(() async {
        final path = Uri(
          path: ApiEndpoints.workersKpiOverview,
          queryParameters: _periodQuery(period),
        ).toString();
        final json = await api.get(path, auth: true);
        final raw = json['items'] as List<dynamic>? ?? const [];
        return [
          for (final item in raw) _kpiFromJson(item as Map<String, dynamic>),
        ];
      });

  @override
  Future<WorkerKpi> saveAssessment({
    required String workerId,
    required KpiPeriod period,
    required Map<KpiAspect, int> scores,
    String? note,
  }) => _guard(() async {
    final cleaned = note?.trim() ?? '';
    final json = await api.put(
      ApiEndpoints.workerKpi(workerId),
      auth: true,
      body: {
        'month': period.month,
        'year': period.year,
        'scores': {
          for (final aspect in KpiAspect.values) aspect.name: scores[aspect],
        },
        if (cleaned.isNotEmpty) 'note': cleaned,
      },
    );
    return _kpiFromJson(json);
  });

  Future<T> _guard<T>(Future<T> Function() run) async {
    try {
      return await run();
    } on AppException catch (e) {
      throw _toFailure(e);
    }
  }

  static Map<String, String> _periodQuery(KpiPeriod period) => {
    'month': '${period.month}',
    'year': '${period.year}',
  };

  static String _date(DateTime d) {
    final month = d.month.toString().padLeft(2, '0');
    final day = d.day.toString().padLeft(2, '0');
    return '${d.year.toString().padLeft(4, '0')}-$month-$day';
  }

  static Map<String, dynamic> _bodyOf(WorkerInput input) {
    final password = input.password ?? '';
    return {
      'full_name': input.fullName.trim(),
      'email': input.email.trim(),
      'phone_number': input.phoneNumber.trim(),
      'employee_code': input.employeeCode.trim(),
      'division': input.division.trim(),
      'join_date': _date(input.joinDate),
      // Kosong saat ubah data = password tidak diganti.
      if (password.isNotEmpty) 'password': password,
    };
  }

  static WorkerProfile _profileFromJson(Map<String, dynamic> json) {
    return WorkerProfile(
      id: json['id'] as String,
      fullName: json['full_name'] as String? ?? '-',
      email: json['email'] as String? ?? '',
      phoneNumber: json['phone_number'] as String? ?? '',
      employeeCode: json['employee_code'] as String,
      division: json['division'] as String,
      joinDate: DateTime.parse(json['join_date'] as String),
      avatarUrl: json['avatar_url'] as String?,
    );
  }

  static WorkerSummary _summaryFromJson(Map<String, dynamic> json) {
    return WorkerSummary(
      profile: _profileFromJson(json),
      avgRating: (json['avg_rating'] as num?)?.toDouble(),
      ratingCount: (json['rating_count'] as num?)?.toInt() ?? 0,
    );
  }

  static WorkerReview _reviewFromJson(Map<String, dynamic> json) {
    return WorkerReview(
      id: json['id'] as String,
      customerName: json['customer_name'] as String? ?? 'Pelanggan Rijiki',
      ratingValue: (json['rating_value'] as num).toInt(),
      createdAt: DateTime.parse(json['created_at'] as String).toLocal(),
      orderNumber: json['order_number'] as String? ?? '-',
      comment: json['comment'] as String?,
      serviceName: json['service_name'] as String?,
    );
  }

  static WorkerKpi _kpiFromJson(Map<String, dynamic> json) {
    KpiAssessment? assessment;
    final raw = json['assessment'] as Map<String, dynamic>?;
    if (raw != null) {
      final rawScores = raw['scores'] as Map<String, dynamic>? ?? const {};
      final scores = <KpiAspect, int>{};
      for (final aspect in KpiAspect.values) {
        final value = rawScores[aspect.name];
        if (value is num) scores[aspect] = value.toInt();
      }
      assessment = KpiAssessment(
        scores: scores,
        note: raw['note'] as String?,
        updatedAt: DateTime.parse(raw['updated_at'] as String).toLocal(),
      );
    }
    return WorkerKpi(
      workerId: json['worker_id'] as String,
      period: KpiPeriod(
        (json['period_month'] as num).toInt(),
        (json['period_year'] as num).toInt(),
      ),
      totalOrdersHandled: (json['total_orders_handled'] as num?)?.toInt() ?? 0,
      avgRating: (json['avg_rating'] as num?)?.toDouble(),
      onTimeCompletionPct: (json['on_time_completion_pct'] as num?)?.toDouble(),
      assessment: assessment,
    );
  }

  Failure _toFailure(AppException e) {
    switch (e.code) {
      case AppException.networkCode:
      case AppException.offlineCode:
      case AppException.timeoutCode:
        return Failure(FailureType.network, e.message, code: e.code);
      case 'unauthorized':
        return Failure(FailureType.unauthorized, e.message, code: e.code);
      case 'validation_error':
        return Failure(FailureType.validation, e.message, code: e.code);
      case 'email_taken':
      case 'employee_code_taken':
      case 'period_closed':
        return Failure(FailureType.conflict, e.message, code: e.code);
    }
    if ((e.statusCode ?? 0) >= 500) {
      return Failure(FailureType.server, e.message, code: e.code);
    }
    return Failure(
      FailureType.unknown,
      e.message.isEmpty ? AppStrings.errUnknown : e.message,
      code: e.code,
    );
  }
}
