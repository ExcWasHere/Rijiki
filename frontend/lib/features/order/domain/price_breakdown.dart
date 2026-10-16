import 'package:flutter/foundation.dart';

@immutable
class PriceBreakdown {
  const PriceBreakdown({
    required this.subtotal,
    this.discount = 0,
    this.shipping = 0,
  });

  final int subtotal;
  final int discount;
  final int shipping;

  int get total => subtotal - discount + shipping;
}
