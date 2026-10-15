import 'package:flutter/foundation.dart';

@immutable
class MerchandiseInput {
  const MerchandiseInput({
    required this.name,
    required this.price,
    this.pointsCost,
    this.stockQuantity,
    this.description,
    this.imageUrl,
    this.isActive = true,
  });

  final String name;
  final int price;
  final int? pointsCost;
  final int? stockQuantity;
  final String? description;
  final String? imageUrl;
  final bool isActive;
}
