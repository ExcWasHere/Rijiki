import 'package:rijiki/core/mock/mock_scenario.dart';
import 'package:rijiki/features/service/domain/care_service.dart';
import 'package:rijiki/features/service/domain/care_service_input.dart';
import 'package:rijiki/features/service/domain/service_repository.dart';

class MockServiceRepository implements ServiceRepository {
  MockServiceRepository({this.scenario = MockScenario.data});

  final MockScenario scenario;

  static const Duration _writeLatency = Duration(milliseconds: 450);

  static const List<CareService> _seed = [
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

  late final List<CareService> _services = List.of(_seed);

  @override
  Future<List<CareService>> fetchServices() {
    return scenario.resolve<List<CareService>>(
      empty: const [],
      data: [
        for (final service in _services)
          if (service.isActive) service,
      ],
    );
  }

  @override
  Future<List<CareService>> fetchAllServices() {
    return scenario.resolve<List<CareService>>(
      empty: const [],
      data: List.of(_services),
    );
  }

  @override
  Future<CareService> createService(CareServiceInput input) async {
    await _write();
    final service = _fromInput(
      'svc-${DateTime.now().microsecondsSinceEpoch}',
      input,
    );
    _services.add(service);
    return service;
  }

  @override
  Future<CareService> updateService(String id, CareServiceInput input) async {
    await _write();
    final index = _indexOf(id);
    final updated = _fromInput(id, input);
    _services[index] = updated;
    return updated;
  }

  @override
  Future<CareService> setServiceActive(String id, bool isActive) async {
    await _write();
    final index = _indexOf(id);
    final updated = _services[index].copyWith(isActive: isActive);
    _services[index] = updated;
    return updated;
  }

  Future<void> _write() async {
    await Future<void>.delayed(_writeLatency);
    if (scenario == MockScenario.error) throw const MockException();
  }

  int _indexOf(String id) {
    final index = _services.indexWhere((s) => s.id == id);
    if (index == -1) throw const MockException('Layanan tidak ditemukan');
    return index;
  }

  static CareService _fromInput(String id, CareServiceInput input) {
    final description = input.description?.trim() ?? '';
    return CareService(
      id: id,
      name: input.name.trim(),
      category: input.category,
      basePrice: input.basePrice,
      description: description.isEmpty ? null : description,
      estimatedDurationMinutes: input.estimatedDurationMinutes,
      isActive: input.isActive,
    );
  }
}
