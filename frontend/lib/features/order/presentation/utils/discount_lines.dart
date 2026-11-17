import 'package:rijiki/features/order/domain/applied_promo.dart';
import 'package:rijiki/features/order/domain/price_breakdown.dart';

typedef DiscountLine = ({String label, int amount});

/// Baris diskon di rincian harga, struk, dan PDF: satu baris per promo.
/// Order tanpa rincian promo (mis. data mock lama) tetap menampilkan satu
/// baris "Diskon" bila ada potongan.
List<DiscountLine> discountLines(
  PriceBreakdown price,
  List<AppliedPromo> promos,
) {
  final lines = [
    for (final promo in promos)
      if (promo.discount > 0) (label: promo.label, amount: promo.discount),
  ];
  if (lines.isEmpty && price.discount > 0) {
    return [(label: 'Diskon', amount: price.discount)];
  }
  return lines;
}
