import 'package:rijiki/core/constants/app_strings.dart';
import 'package:rijiki/core/error/app_exception.dart';
import 'package:rijiki/core/error/failure.dart';
import 'package:rijiki/core/network/api_client.dart';
import 'package:rijiki/core/network/api_endpoint.dart';
import 'package:rijiki/features/points/domain/point_rule.dart';
import 'package:rijiki/features/points/domain/point_rule_repository.dart';

/// Aturan poin dari backend (`/api/management/point-rules`).
/// Perubahan berlaku untuk transaksi berikutnya; poin yang sudah masuk tidak berubah.
class PointRuleRepositoryImpl implements PointRuleRepository {
  PointRuleRepositoryImpl({required this.api});

  final ApiClient api;

  @override
  Future<List<PointRule>> fetchRules() async {
    try {
      final json = await api.get(ApiEndpoints.pointRules, auth: true);
      final raw = json['items'] as List<dynamic>? ?? const [];
      return [
        for (final item in raw) PointRule.fromJson(item as Map<String, dynamic>),
      ];
    } on AppException catch (e) {
      throw _toFailure(e);
    }
  }

  @override
  Future<PointRule> updateRule(String id, PointRuleInput input) async {
    try {
      final json = await api.patch(
        ApiEndpoints.pointRuleById(id),
        auth: true,
        body: input.toJson(),
      );
      return PointRule.fromJson(json);
    } on AppException catch (e) {
      throw _toFailure(e);
    }
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
