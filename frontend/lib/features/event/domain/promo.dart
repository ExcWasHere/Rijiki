import 'package:flutter/foundation.dart';
import 'package:rijiki/core/enums/discount_type.dart';

@immutable
class Promo {
  const Promo({
    required this.id,
    required this.code,
    required this.title,
    required this.discountType,
    required this.discountValue,
    required this.startDate,
    required this.endDate,
    this.description,
    this.isActive = true,
  });

  final String id;
  final String code;
  final String title;
  final DiscountType discountType;
  final int discountValue;
  final DateTime startDate;
  final DateTime endDate;
  final String? description;
  final bool isActive;

  factory Promo.fromJson(Map<String, dynamic> json) {
    return Promo(
      id: json['id'] as String,
      code: json['code'] as String,
      title: json['title'] as String,
      discountType: DiscountType.fromJson(json['discount_type'] as String),
      discountValue: num.parse(json['discount_value'].toString()).round(),
      startDate: DateTime.parse(json['start_date'] as String),
      endDate: DateTime.parse(json['end_date'] as String),
      description: json['description'] as String?,
      isActive: json['is_active'] as bool? ?? true,
    );
  }

  Promo copyWith({bool? isActive}) {
    return Promo(
      id: id,
      code: code,
      title: title,
      discountType: discountType,
      discountValue: discountValue,
      startDate: startDate,
      endDate: endDate,
      description: description,
      isActive: isActive ?? this.isActive,
    );
  }
}
