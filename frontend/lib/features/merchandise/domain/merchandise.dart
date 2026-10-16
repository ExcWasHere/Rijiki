import 'package:flutter/foundation.dart';

@immutable
class Merchandise {
  const Merchandise({
    required this.id,
    required this.name,
    required this.price,
    this.pointsCost,
    this.stockQuantity,
    this.description,
    this.imageUrl,
    this.isActive = true,
  });

  final String id;
  final String name;
  final int price;
  final int? pointsCost;
  final int? stockQuantity;
  final String? description;
  final String? imageUrl;
  final bool isActive;

  bool get isRedeemable => pointsCost != null;
  bool get isOutOfStock => stockQuantity != null && stockQuantity! <= 0;

  factory Merchandise.fromJson(Map<String, dynamic> json) {
    return Merchandise(
      id: json['id'] as String,
      name: json['name'] as String,
      price: (json['price'] as num).round(),
      pointsCost: json['points_cost'] as int?,
      stockQuantity: json['stock_quantity'] as int?,
      description: json['description'] as String?,
      imageUrl: json['image_url'] as String?,
      isActive: json['is_active'] as bool? ?? true,
    );
  }

  Merchandise copyWith({bool? isActive}) {
    return Merchandise(
      id: id,
      name: name,
      price: price,
      pointsCost: pointsCost,
      stockQuantity: stockQuantity,
      description: description,
      imageUrl: imageUrl,
      isActive: isActive ?? this.isActive,
    );
  }
}
