import 'package:flutter/foundation.dart';

/// Ringkasan promo yang menempel pada event (dari GET /api/events).
@immutable
class EventPromo {
  const EventPromo({
    required this.id,
    required this.code,
    required this.title,
    required this.isPercentage,
    required this.discountValue,
    required this.appliesToShipping,
    required this.startDate,
    required this.endDate,
    required this.isActive,
    required this.available,
    this.description,
    this.minSubtotal,
    this.maxDiscountAmount,
    this.quotaLeft,
    this.firstOrderOnly = false,
  });

  final String id;
  final String code;
  final String title;
  final String? description;

  /// true = diskon persen, false = potongan nominal.
  final bool isPercentage;
  final int discountValue;

  /// true = potongan ongkir, false = potongan harga layanan.
  final bool appliesToShipping;
  final int? minSubtotal;
  final int? maxDiscountAmount;
  final bool firstOrderOnly;
  final DateTime startDate;
  final DateTime endDate;
  final bool isActive;

  /// Sisa kuota total; null = tanpa batas.
  final int? quotaLeft;

  /// Aktif, dalam periode, dan kuota belum habis (dihitung backend).
  final bool available;

  factory EventPromo.fromJson(Map<String, dynamic> json) {
    int? optInt(Object? value) =>
        value == null ? null : num.parse(value.toString()).round();

    return EventPromo(
      id: json['id'] as String,
      code: json['code'] as String,
      title: json['title'] as String,
      description: json['description'] as String?,
      isPercentage: json['discount_type'] == 'percentage',
      discountValue: optInt(json['discount_value']) ?? 0,
      appliesToShipping: json['applies_to'] == 'shipping',
      minSubtotal: optInt(json['min_subtotal']),
      maxDiscountAmount: optInt(json['max_discount_amount']),
      firstOrderOnly: json['first_order_only'] as bool? ?? false,
      startDate: DateTime.parse(json['start_date'] as String),
      endDate: DateTime.parse(json['end_date'] as String),
      isActive: json['is_active'] as bool? ?? true,
      quotaLeft: optInt(json['quota_left']),
      available: json['available'] as bool? ?? true,
    );
  }
}
