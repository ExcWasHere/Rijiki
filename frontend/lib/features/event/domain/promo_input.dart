import 'package:flutter/foundation.dart';
import 'package:rijiki/core/enums/discount_type.dart';
import 'package:rijiki/core/enums/promo_applies_to.dart';

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
    this.appliesTo = PromoAppliesTo.subtotal,
    this.minSubtotal,
    this.maxDiscountAmount,
    this.usageLimit,
    this.usageLimitPerCustomer,
    this.firstOrderOnly = false,
    this.serviceIds = const [],
    this.idempotencyKey,
  });

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

  final String? idempotencyKey;

  static String _date(DateTime d) {
    final month = d.month.toString().padLeft(2, '0');
    final day = d.day.toString().padLeft(2, '0');
    return '${d.year.toString().padLeft(4, '0')}-$month-$day';
  }

  Map<String, dynamic> toJson() {
    final text = description?.trim() ?? '';
    return {
      'code': code,
      'title': title,
      'description': text.isEmpty ? null : text,
      'discount_type': discountType.toJson(),
      'discount_value': discountValue,
      'start_date': _date(startDate),
      'end_date': _date(endDate),
      'is_active': isActive,
      'applies_to': appliesTo.toJson(),
      'min_subtotal': minSubtotal,
      'max_discount_amount': maxDiscountAmount,
      'usage_limit': usageLimit,
      'usage_limit_per_customer': usageLimitPerCustomer,
      'first_order_only': firstOrderOnly,
      'service_ids': serviceIds,
    };
  }
}
