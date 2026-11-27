import 'package:flutter/foundation.dart';

enum PointRuleSource {
  orderCompleted('order_completed'),
  giveRating('give_rating'),
  referral('referral'),
  promoBonus('promo_bonus'),
  manual('manual');

  const PointRuleSource(this.value);

  final String value;

  static PointRuleSource fromJson(String? value) {
    return PointRuleSource.values.firstWhere(
      (source) => source.value == value,
      orElse: () => PointRuleSource.manual,
    );
  }
}

enum PointCalculationType {
  fixed('fixed'),
  perAmount('per_amount');

  const PointCalculationType(this.value);

  final String value;

  static PointCalculationType fromJson(String? value) {
    return PointCalculationType.values.firstWhere(
      (type) => type.value == value,
      orElse: () => PointCalculationType.fixed,
    );
  }
}

@immutable
class PointRule {
  const PointRule({
    required this.id,
    required this.source,
    required this.calculationType,
    required this.pointsValue,
    this.amountUnit,
    this.isActive = true,
  });

  final String id;
  final PointRuleSource source;
  final PointCalculationType calculationType;

  /// Poin tetap per aksi (fixed), atau poin per [amountUnit] rupiah (per_amount).
  final int pointsValue;
  final int? amountUnit;
  final bool isActive;

  factory PointRule.fromJson(Map<String, dynamic> json) {
    final unit = json['amount_unit'];
    return PointRule(
      id: json['id'] as String,
      source: PointRuleSource.fromJson(json['source'] as String?),
      calculationType: PointCalculationType.fromJson(
        json['calculation_type'] as String?,
      ),
      pointsValue: num.parse(json['points_value'].toString()).round(),
      amountUnit: unit == null ? null : num.parse(unit.toString()).round(),
      isActive: json['is_active'] as bool? ?? true,
    );
  }

  PointRule copyWith({int? pointsValue, int? amountUnit, bool? isActive}) {
    return PointRule(
      id: id,
      source: source,
      calculationType: calculationType,
      pointsValue: pointsValue ?? this.pointsValue,
      amountUnit: amountUnit ?? this.amountUnit,
      isActive: isActive ?? this.isActive,
    );
  }
}

/// Perubahan yang dikirim ke backend. Hanya nilai yang bisa diubah dari aplikasi.
@immutable
class PointRuleInput {
  const PointRuleInput({required this.pointsValue, this.amountUnit});

  final int pointsValue;

  /// Hanya untuk aturan per nominal.
  final int? amountUnit;

  Map<String, dynamic> toJson() => {
    'points_value': pointsValue,
    if (amountUnit != null) 'amount_unit': amountUnit,
  };
}
