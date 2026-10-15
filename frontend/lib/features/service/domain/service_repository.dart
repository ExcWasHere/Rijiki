import 'package:rijiki/features/service/domain/care_service.dart';
import 'package:rijiki/features/service/domain/care_service_input.dart';

abstract interface class ServiceRepository {
  Future<List<CareService>> fetchServices();
  Future<List<CareService>> fetchAllServices();
  Future<CareService> createService(CareServiceInput input);
  Future<CareService> updateService(String id, CareServiceInput input);
  Future<CareService> setServiceActive(String id, bool isActive);
}
