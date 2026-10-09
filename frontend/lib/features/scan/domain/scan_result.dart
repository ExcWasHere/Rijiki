import 'package:flutter/foundation.dart';
import 'package:rijiki/features/service/domain/care_service.dart';

@immutable
class ScanPrediction {
  const ScanPrediction({required this.label, required this.confidence});

  final String label;
  final double confidence;
}

@immutable
class ScanResult {
  const ScanResult({
    required this.shoeType,
    required this.material,
    required this.conditions,
    required this.recommendedService,
    required this.recommendationReason,
    required this.modelVersion,
  });

  final ScanPrediction shoeType;
  final ScanPrediction material;
  final List<ScanPrediction> conditions;

  final CareService recommendedService;
  final String recommendationReason;
  final String modelVersion;
}
