import 'package:rijiki/core/constants/app_strings.dart';
import 'package:rijiki/core/error/app_exception.dart';
import 'package:rijiki/core/error/failure.dart';
import 'package:rijiki/core/network/api_client.dart';
import 'package:rijiki/core/network/api_endpoint.dart';
import 'package:rijiki/features/service/domain/care_service.dart';
import 'package:rijiki/features/service/domain/care_service_input.dart';
import 'package:rijiki/features/service/domain/service_repository.dart';

/// Katalog layanan untuk customer diambil dari backend (`GET /api/services`).
///
/// TODO(cms): fungsi CMS (fetchAllServices, create, update, setActive) belum
/// punya endpoint di backend, jadi sementara didelegasikan ke [cms] (mock).
/// Akibatnya perubahan layanan lewat CMS belum memengaruhi katalog asli.
class ServiceRepositoryImpl implements ServiceRepository {
  ServiceRepositoryImpl({required this.api, required this.cms});

  final ApiClient api;
  final ServiceRepository cms;

  @override
  Future<List<CareService>> fetchServices() async {
    try {
      final json = await api.get(ApiEndpoints.services);
      final raw = json['items'] as List<dynamic>? ?? const [];
      return [
        for (final item in raw) CareService.fromJson(item as Map<String, dynamic>),
      ];
    } on AppException catch (e) {
      throw _toFailure(e);
    }
  }

  @override
  Future<List<CareService>> fetchAllServices() => cms.fetchAllServices();

  @override
  Future<CareService> createService(CareServiceInput input) =>
      cms.createService(input);

  @override
  Future<CareService> updateService(String id, CareServiceInput input) =>
      cms.updateService(id, input);

  @override
  Future<CareService> setServiceActive(String id, bool isActive) =>
      cms.setServiceActive(id, isActive);

  Failure _toFailure(AppException e) {
    if (e.isNetwork) {
      return Failure(FailureType.network, e.message, code: e.code);
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
