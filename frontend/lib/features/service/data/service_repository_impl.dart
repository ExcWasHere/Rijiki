import 'package:rijiki/core/error/app_exception.dart';
import 'package:rijiki/core/error/failure_mapper.dart';
import 'package:rijiki/core/network/api_client.dart';
import 'package:rijiki/core/network/api_endpoint.dart';
import 'package:rijiki/features/service/domain/care_service.dart';
import 'package:rijiki/features/service/domain/care_service_input.dart';
import 'package:rijiki/features/service/domain/service_repository.dart';

/// Katalog layanan: `GET /api/services` publik untuk customer, dan
/// `GET /api/services/manage` + `POST/PATCH /api/services` untuk CMS
/// (izin `manage_cms_services`). Semua data berasal dari tabel `services`.
class ServiceRepositoryImpl implements ServiceRepository {
  ServiceRepositoryImpl({required this.api});

  final ApiClient api;

  @override
  Future<List<CareService>> fetchServices() =>
      _fetch(ApiEndpoints.services, auth: false);

  @override
  Future<List<CareService>> fetchAllServices() =>
      _fetch(ApiEndpoints.managementServices, auth: true);

  Future<List<CareService>> _fetch(String path, {required bool auth}) async {
    try {
      final json = await api.get(path, auth: auth);
      final raw = json['items'] as List<dynamic>? ?? const [];
      return [
        for (final item in raw) CareService.fromJson(item as Map<String, dynamic>),
      ];
    } on AppException catch (e) {
      throw failureFromException(e);
    }
  }

  @override
  Future<CareService> createService(CareServiceInput input) async {
    try {
      final json = await api.post(
        ApiEndpoints.services,
        auth: true,
        body: _payload(input),
      );
      return CareService.fromJson(json);
    } on AppException catch (e) {
      throw failureFromException(e);
    }
  }

  @override
  Future<CareService> updateService(String id, CareServiceInput input) async {
    try {
      final json = await api.patch(
        ApiEndpoints.serviceById(id),
        auth: true,
        body: _payload(input),
      );
      return CareService.fromJson(json);
    } on AppException catch (e) {
      throw failureFromException(e);
    }
  }

  @override
  Future<CareService> setServiceActive(String id, bool isActive) async {
    try {
      final json = await api.patch(
        ApiEndpoints.serviceById(id),
        auth: true,
        body: {'is_active': isActive},
      );
      return CareService.fromJson(json);
    } on AppException catch (e) {
      throw failureFromException(e);
    }
  }

  static Map<String, dynamic> _payload(CareServiceInput input) {
    final description = input.description?.trim();
    return {
      'name': input.name.trim(),
      'category': input.category.json,
      'base_price': input.basePrice,
      'description': description == null || description.isEmpty ? null : description,
      'estimated_duration_minutes': input.estimatedDurationMinutes,
      'is_active': input.isActive,
    };
  }
}
