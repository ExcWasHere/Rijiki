import 'package:rijiki/core/constants/app_strings.dart';
import 'package:rijiki/core/error/app_exception.dart';
import 'package:rijiki/core/error/failure.dart';
import 'package:rijiki/core/network/api_client.dart';
import 'package:rijiki/core/network/api_endpoint.dart';
import 'package:rijiki/features/event/domain/promo.dart';
import 'package:rijiki/features/event/domain/promo_input.dart';
import 'package:rijiki/features/event/domain/promo_repository.dart';

class PromoRepositoryImpl implements PromoRepository {
  PromoRepositoryImpl({required this.api});

  final ApiClient api;

  @override
  Future<List<Promo>> fetchAllPromos() async {
    try {
      final json = await api.get(ApiEndpoints.promos, auth: true);
      final raw = json['items'] as List<dynamic>? ?? const [];
      return [
        for (final item in raw) Promo.fromJson(item as Map<String, dynamic>),
      ];
    } on AppException catch (e) {
      throw _toFailure(e);
    }
  }

  @override
  Future<Promo> createPromo(PromoInput input) async {
    try {
      final key = input.idempotencyKey;
      final json = await api.post(
        ApiEndpoints.promos,
        auth: true,
        body: input.toJson(),
        headers: key == null ? null : {ApiClient.idempotencyHeader: key},
      );
      return Promo.fromJson(json);
    } on AppException catch (e) {
      throw _toFailure(e);
    }
  }

  @override
  Future<Promo> updatePromo(String id, PromoInput input) async {
    try {
      final json = await api.patch(
        ApiEndpoints.promoById(id),
        auth: true,
        body: input.toJson(),
      );
      return Promo.fromJson(json);
    } on AppException catch (e) {
      throw _toFailure(e);
    }
  }

  @override
  Future<Promo> setPromoActive(String id, bool isActive) async {
    try {
      final json = await api.patch(
        ApiEndpoints.promoById(id),
        auth: true,
        body: {'is_active': isActive},
      );
      return Promo.fromJson(json);
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
      case 'promo_code_taken':
      case 'promo_code_locked':
      case 'idempotency_conflict':
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
