import 'package:flutter/foundation.dart';
import 'package:rijiki/features/service/domain/care_service.dart';

@immutable
class CareServiceInput {
  const CareServiceInput({
    required this.name,
    required this.category,
    required this.basePrice,
    this.description,
    this.estimatedDurationMinutes,
    this.isActive = true,
  });

  final String name;
  final ServiceCategory category;
  final int basePrice;
  final String? description;
  final int? estimatedDurationMinutes;
  final bool isActive;
}
