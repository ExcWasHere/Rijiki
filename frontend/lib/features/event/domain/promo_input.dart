import 'package:flutter/foundation.dart';
import 'package:rijiki/core/enums/discount_type.dart';

@immutable
class PromoInput {
  const PromoInput({
    required this.code,
    required this.title,
    required this.discountType,
    required this.discountValue,
    required this.startDate,
    required this.endDate,
    this.description,
    this.isActive = true,
  });

  final String code;
  final String title;
  final DiscountType discountType;
  final int discountValue;
  final DateTime startDate;
  final DateTime endDate;
  final String? description;
  final bool isActive;
}
