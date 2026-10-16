import 'package:flutter/foundation.dart';
import 'package:rijiki/features/order/domain/price_breakdown.dart';

@immutable
class PriceQuote {
  const PriceQuote({
    required this.price,
    this.promoCode,
    this.promoDescription,
  });

  final PriceBreakdown price;
  final String? promoCode;
  final String? promoDescription;
}

class PromoException implements Exception {
  const PromoException(this.message);

  final String message;

  @override
  String toString() => message;
}
