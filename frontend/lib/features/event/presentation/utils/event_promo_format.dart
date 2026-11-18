import 'package:rijiki/core/utils/rupiah_formatter.dart';
import 'package:rijiki/features/event/domain/event_promo.dart';

/// Tanpa spasi setelah "Rp" agar label promo tetap ringkas.
String formatRupiahInt(int value) => 'Rp${RupiahFormatter.grouped(value)}';

extension EventPromoFormat on EventPromo {
  /// Contoh: "Diskon 20%", "Diskon Rp10.000", "Diskon ongkir 50%".
  String get discountLabel {
    final value = isPercentage ? '$discountValue%' : formatRupiahInt(discountValue);
    return '${appliesToShipping ? 'Diskon ongkir' : 'Diskon'} $value';
  }

  /// Syarat singkat untuk ditampilkan di detail promo.
  List<String> get conditions {
    final min = minSubtotal;
    final max = maxDiscountAmount;
    final quota = quotaLeft;
    return [
      if (min != null && min > 0) 'Min. belanja ${formatRupiahInt(min)}',
      if (isPercentage && max != null) 'Maks. potongan ${formatRupiahInt(max)}',
      if (firstOrderOnly) 'Khusus order pertama',
      if (quota != null) 'Sisa kuota $quota',
    ];
  }
}
