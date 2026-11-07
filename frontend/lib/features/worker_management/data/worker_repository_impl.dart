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

/// Data karyawan dari backend: daftar, tambah, dan ubah.
///
/// TODO(segmen-4b): ulasan, KPI, dan penilaian belum punya endpoint, jadi
/// sementara didelegasikan ke [fallback] (mock). Id worker asli tidak dikenal
/// mock, sehingga bagian itu bisa kosong atau galat untuk worker asli.
class WorkerRepositoryImpl implements WorkerRepository {
  WorkerRepositoryImpl({required this.api, required this.fallback});

  final ApiClient api;
  final WorkerRepository fallback;

  @override
  Future<List<WorkerSummary>> fetchWorkers() async {
    try {
      final json = await api.get('${ApiEndpoints.workers}/manage', auth: true);
      final raw = json['items'] as List<dynamic>? ?? const [];
      return [
        for (final item in raw) _summaryFromJson(item as Map<String, dynamic>),
      ];
    } on AppException catch (e) {
      throw _toFailure(e);
    }
  }

  @override
  Future<WorkerProfile> createWorker(WorkerInput input) async {
    try {
      final json = await api.post(
        ApiEndpoints.workers,
        auth: true,
        body: _bodyOf(input),
      );
      return _profileFromJson(json);
    } on AppException catch (e) {
      throw _toFailure(e);
    }
  }

  @override
  Future<WorkerProfile> updateWorker(String id, WorkerInput input) async {
    try {
      final json = await api.patch(
        '${ApiEndpoints.workers}/$id',
        auth: true,
        body: _bodyOf(input),
      );
      return _profileFromJson(json);
    } on AppException catch (e) {
      throw _toFailure(e);
    }
  }

  @override
  Future<List<WorkerReview>> fetchReviews(String workerId) =>
      fallback.fetchReviews(workerId);

  @override
  Future<WorkerKpi> fetchKpi(String workerId, KpiPeriod period) =>
      fallback.fetchKpi(workerId, period);

  @override
  Future<List<WorkerKpi>> fetchKpiOverview(KpiPeriod period) =>
      fallback.fetchKpiOverview(period);

  @override
  Future<WorkerKpi> saveAssessment({
    required String workerId,
    required KpiPeriod period,
    required Map<KpiAspect, int> scores,
    String? note,
  }) => fallback.saveAssessment(
    workerId: workerId,
    period: period,
    scores: scores,
    note: note,
  );

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
