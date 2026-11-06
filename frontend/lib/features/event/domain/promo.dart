import 'package:flutter/foundation.dart';
import 'package:rijiki/core/enums/discount_type.dart';
import 'package:rijiki/core/enums/promo_applies_to.dart';

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
    this.appliesTo = PromoAppliesTo.subtotal,
    this.minSubtotal,
    this.maxDiscountAmount,
    this.usageLimit,
    this.usageLimitPerCustomer,
    this.firstOrderOnly = false,
    this.serviceIds = const [],
    this.usageCount = 0,
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
  final PromoAppliesTo appliesTo;
  final int? minSubtotal;
  final int? maxDiscountAmount;
  final int? usageLimit;
  final int? usageLimitPerCustomer;
  final bool firstOrderOnly;
  final List<String> serviceIds;
  final int usageCount;
  bool get isCodeLocked => usageCount > 0;

  factory Promo.fromJson(Map<String, dynamic> json) {
    int? optInt(Object? value) =>
        value == null ? null : num.parse(value.toString()).round();

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
      appliesTo: PromoAppliesTo.fromJson(json['applies_to'] as String?),
      minSubtotal: optInt(json['min_subtotal']),
      maxDiscountAmount: optInt(json['max_discount_amount']),
      usageLimit: optInt(json['usage_limit']),
      usageLimitPerCustomer: optInt(json['usage_limit_per_customer']),
      firstOrderOnly: json['first_order_only'] as bool? ?? false,
      serviceIds: [
        for (final id in (json['service_ids'] as List<dynamic>? ?? const []))
          id as String,
      ],
      usageCount: optInt(json['usage_count']) ?? 0,
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
      appliesTo: appliesTo,
      minSubtotal: minSubtotal,
      maxDiscountAmount: maxDiscountAmount,
      usageLimit: usageLimit,
      usageLimitPerCustomer: usageLimitPerCustomer,
      firstOrderOnly: firstOrderOnly,
      serviceIds: serviceIds,
      usageCount: usageCount,
    );
  }
}
