import 'package:flutter/foundation.dart';
import 'package:rijiki/features/order/domain/applied_promo.dart';
import 'package:rijiki/features/order/domain/price_breakdown.dart';

@immutable
class PriceQuote {
  const PriceQuote({required this.price, this.promos = const []});

  final PriceBreakdown price;
  final List<AppliedPromo> promos;

  List<String> get promoCodes => [for (final promo in promos) promo.code];
}

class PromoException implements Exception {
  const PromoException(this.message);

  final String message;

  @override
  String toString() => message;
}
