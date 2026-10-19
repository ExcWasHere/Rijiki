import 'package:flutter/material.dart';
import 'package:rijiki/core/enums/discount_type.dart';
import 'package:rijiki/core/theme/app_colors.dart';
import 'package:rijiki/core/utils/date_format.dart';
import 'package:rijiki/core/utils/rupiah_formatter.dart';
import 'package:rijiki/features/event/domain/promo.dart';

enum PromoPhase { upcoming, running, ended }

extension PromoPhaseX on PromoPhase {
  String get label => switch (this) {
    PromoPhase.upcoming => 'Akan datang',
    PromoPhase.running => 'Berlangsung',
    PromoPhase.ended => 'Berakhir',
  };

  Color get color => switch (this) {
    PromoPhase.upcoming => AppColors.primaryDark,
    PromoPhase.running => AppColors.success,
    PromoPhase.ended => AppColors.onSurfaceVariant,
  };
}

extension DiscountTypeCmsX on DiscountType {
  String get cmsLabel => switch (this) {
    DiscountType.percentage => 'Persen (%)',
    DiscountType.fixed => 'Nominal (Rp)',
  };
}

DateTime _dateOnly(DateTime d) => DateTime(d.year, d.month, d.day);

PromoPhase promoPhaseOf(Promo promo, {DateTime? now}) {
  final today = _dateOnly(now ?? DateTime.now());
  if (today.isBefore(_dateOnly(promo.startDate))) return PromoPhase.upcoming;
  if (today.isAfter(_dateOnly(promo.endDate))) return PromoPhase.ended;
  return PromoPhase.running;
}

String formatPromoValue(Promo promo) => switch (promo.discountType) {
  DiscountType.percentage => '${promo.discountValue}%',
  DiscountType.fixed => RupiahFormatter.full(promo.discountValue.toDouble()),
};

String compactPromoValue(Promo promo) {
  final v = promo.discountValue;
  if (promo.discountType == DiscountType.percentage) return '$v%';
  if (v >= 1000000 && v % 1000000 == 0) return '${v ~/ 1000000}jt';
  if (v >= 1000 && v % 1000 == 0) return '${v ~/ 1000}rb';
  return '$v';
}

String formatPromoPeriod(DateTime start, DateTime end) {
  return '${formatDate(start)} – ${formatDate(end)}';
}
