import 'package:flutter/foundation.dart';

enum ServiceCategory {
  cuciSepatu('cuci_sepatu', 'Cuci sepatu'),
  reparasi('reparasi', 'Reparasi');

  const ServiceCategory(this.json, this.label);

  final String json;
  final String label;

  static ServiceCategory fromJson(String value) {
    return ServiceCategory.values.firstWhere(
      (category) => category.json == value,
      orElse: () =>
          throw ArgumentError('ServiceCategory tidak dikenal: $value'),
    );
  }
}

@immutable
class CareService {
  const CareService({
    required this.id,
    required this.name,
    required this.category,
    required this.basePrice,
    this.description,
    this.estimatedDurationMinutes,
  });

  final String id;
  final String name;
  final ServiceCategory category;
  final int basePrice;
  final String? description;
  final int? estimatedDurationMinutes;

  factory CareService.fromJson(Map<String, dynamic> json) {
    return CareService(
      id: json['id'] as String,
      name: json['name'] as String,
      category: ServiceCategory.fromJson(json['category'] as String),
      basePrice: (json['base_price'] as num).round(),
      description: json['description'] as String?,
      estimatedDurationMinutes: json['estimated_duration_minutes'] as int?,
    );
  }
}
