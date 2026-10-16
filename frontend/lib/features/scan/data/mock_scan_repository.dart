import 'package:rijiki/core/mock/mock_scenario.dart';
import 'package:rijiki/features/scan/domain/scan_repository.dart';
import 'package:rijiki/features/scan/domain/scan_result.dart';
import 'package:rijiki/features/service/domain/care_service.dart';

class MockScanRepository implements ScanRepository {
  const MockScanRepository({this.scenario = MockScenario.data});

  final MockScenario scenario;

  static const ScanResult _result = ScanResult(
    shoeType: ScanPrediction(label: 'Sneakers', confidence: 0.94),
    material: ScanPrediction(label: 'Leather', confidence: 0.88),
    conditions: [
      ScanPrediction(label: 'Heavy Dirt / Stain', confidence: 0.91),
      ScanPrediction(label: 'Yellowing', confidence: 0.64),
    ],
    recommendedService: CareService(
      id: 'svc-deep',
      name: 'Deep Clean',
      category: ServiceCategory.cuciSepatu,
      basePrice: 40000,
      description: 'Pembersihan total hingga sole dalam dan detail alas',
    ),
    recommendationReason:
        'Noda cukup berat dan sole mulai menguning, jadi butuh pembersihan menyeluruh.',
    modelVersion: 'mobilenetv3-mock-0.1',
  );

  @override
  Future<ScanResult> analyze(String imagePath) async {
    await Future<void>.delayed(const Duration(seconds: 2));
    return switch (scenario) {
      MockScenario.data => _result,
      MockScenario.empty => throw const ScanException(
        'Sepatu tidak terdeteksi di foto. Coba foto ulang dengan cahaya lebih terang.',
      ),
      MockScenario.error => throw const MockException(),
    };
  }
}
