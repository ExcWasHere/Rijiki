import 'package:rijiki/features/service/domain/care_service.dart';

abstract interface class ServiceRepository {
  Future<List<CareService>> fetchServices();
}
