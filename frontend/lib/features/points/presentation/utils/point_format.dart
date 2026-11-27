import 'package:rijiki/core/utils/rupiah_formatter.dart';
import 'package:rijiki/features/points/domain/point_rule.dart';

extension PointRuleSourceX on PointRuleSource {
  String get title => switch (this) {
    PointRuleSource.orderCompleted => 'Order selesai',
    PointRuleSource.giveRating => 'Memberi rating',
    PointRuleSource.referral => 'Referral',
    PointRuleSource.promoBonus => 'Bonus promo',
    PointRuleSource.manual => 'Manual',
  };

  String get shortTitle => switch (this) {
    PointRuleSource.giveRating => 'Rating',
    _ => title,
  };

  String get hint => switch (this) {
    PointRuleSource.orderCompleted =>
      'Didapat customer saat ordernya berstatus selesai.',
    PointRuleSource.giveRating =>
      'Didapat customer setelah memberi rating untuk order.',
    PointRuleSource.referral => 'Didapat dari ajakan teman.',
    PointRuleSource.promoBonus => 'Didapat dari promo bonus.',
    PointRuleSource.manual => 'Koreksi manual oleh owner atau worker berizin.',
  };
}

/// "100 poin" untuk aturan tetap, "10 poin / Rp1.000" untuk aturan per nominal.
String formatPointRuleValue(PointRule rule) {
  if (rule.calculationType == PointCalculationType.perAmount &&
      rule.amountUnit != null) {
    return '${rule.pointsValue} poin / '
        '${RupiahFormatter.full(rule.amountUnit!.toDouble())}';
  }
  return '${rule.pointsValue} poin';
}
