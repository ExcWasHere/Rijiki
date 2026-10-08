import 'package:rijiki/core/mock/mock_scenario.dart';
import 'package:rijiki/features/service/domain/care_service.dart';
import 'package:rijiki/features/service/domain/service_repository.dart';

class MockServiceRepository implements ServiceRepository {
  const MockServiceRepository({this.scenario = MockScenario.data});

  final MockScenario scenario;

  static const List<CareService> _services = [
    CareService(
      id: 'svc-reguler',
      name: 'Reguler Treatment',
      category: ServiceCategory.cuciSepatu,
      basePrice: 25000,
      description: 'Pembersihan ringan bagian dalam dan luar sepatu',
    ),
    CareService(
      id: 'svc-fast',
      name: 'Fast Clean',
      category: ServiceCategory.cuciSepatu,
      basePrice: 30000,
      description: 'Selesai cuci dan kering sebelum 24 jam',
      estimatedDurationMinutes: 1440,
    ),
    CareService(
      id: 'svc-deep',
      name: 'Deep Clean',
      category: ServiceCategory.cuciSepatu,
      basePrice: 40000,
      description: 'Pembersihan total hingga sole dalam dan detail alas',
    ),
    CareService(
      id: 'svc-gunung',
      name: 'Sepatu Gunung',
      category: ServiceCategory.cuciSepatu,
      basePrice: 45000,
    ),
    CareService(
      id: 'svc-sandal',
      name: 'Cuci Sandal',
      category: ServiceCategory.cuciSepatu,
      basePrice: 18000,
      description: 'Pembersihan menyeluruh',
    ),
    CareService(
      id: 'svc-glue',
      name: 'Glue Repair',
      category: ServiceCategory.reparasi,
      basePrice: 15000,
      description: 'Pengeleman ulang bagian sole yang terbuka',
    ),
    CareService(
      id: 'svc-glue-plus',
      name: 'Glue Repair Plus',
      category: ServiceCategory.reparasi,
      basePrice: 35000,
      description: 'Lem ulang ditambah cuci reguler',
    ),
    CareService(
      id: 'svc-reglue',
      name: 'Reglue',
      category: ServiceCategory.reparasi,
      basePrice: 50000,
      description: 'Pengeleman ulang seluruh sole sepatu',
    ),
    CareService(
      id: 'svc-jahit',
      name: 'Jahit Sepatu',
      category: ServiceCategory.reparasi,
      basePrice: 25000,
    ),
    CareService(
      id: 'svc-unyellowing',
      name: 'Unyellowing',
      category: ServiceCategory.reparasi,
      basePrice: 30000,
      description: 'Mencerahkan kembali sole yang menguning',
    ),
  ];

  @override
  Future<List<CareService>> fetchServices() {
    return scenario.resolve<List<CareService>>(empty: const [], data: _services);
  }
}
