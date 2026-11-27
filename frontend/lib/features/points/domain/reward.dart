import 'package:flutter/foundation.dart';

/// Hadiah yang bisa ditukar dengan poin (GET /api/points/rewards).
@immutable
class Reward {
  const Reward({
    required this.id,
    required this.name,
    required this.pointsCost,
    required this.inStock,
    this.description,
    this.imageUrl,
  });

  /// merchandise.id; dikirim saat mengajukan penukaran.
  final String id;
  final String name;
  final String? description;
  final String? imageUrl;
  final int pointsCost;
  final bool inStock;

  factory Reward.fromJson(Map<String, dynamic> json) {
    return Reward(
      id: json['id'] as String,
      name: json['name'] as String,
      description: json['description'] as String?,
      imageUrl: json['image_url'] as String?,
      pointsCost: (json['points_cost'] as num? ?? 0).round(),
      inStock: json['in_stock'] as bool? ?? true,
    );
  }
}
