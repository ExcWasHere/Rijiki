import 'package:flutter/foundation.dart';

enum PointLedgerType {
  earn('earn'),
  redeem('redeem'),
  adjustment('adjustment'),
  expire('expire');

  const PointLedgerType(this.value);

  final String value;

  static PointLedgerType fromJson(String? value) {
    return PointLedgerType.values.firstWhere(
      (type) => type.value == value,
      orElse: () => PointLedgerType.adjustment,
    );
  }
}

@immutable
class PointLedgerEntry {
  const PointLedgerEntry({
    required this.id,
    required this.type,
    required this.pointsAmount,
    required this.createdAt,
    this.description,
    this.orderNumber,
  });

  final String id;
  final PointLedgerType type;
  final int pointsAmount;
  final String? description;
  final String? orderNumber;
  final DateTime createdAt;

  factory PointLedgerEntry.fromJson(Map<String, dynamic> json) {
    return PointLedgerEntry(
      id: json['id'] as String,
      type: PointLedgerType.fromJson(json['type'] as String?),
      pointsAmount: (json['points_amount'] as num? ?? 0).round(),
      description: json['description'] as String?,
      orderNumber: json['order_number'] as String?,
      createdAt:
          DateTime.tryParse(json['created_at'] as String? ?? '') ??
          DateTime.now(),
    );
  }
}

@immutable
class PointLedgerPage {
  const PointLedgerPage({required this.items, required this.total});

  final List<PointLedgerEntry> items;
  final int total;
}

@immutable
class PointBalance {
  const PointBalance({required this.balance, this.recent = const []});

  final int balance;
  final List<PointLedgerEntry> recent;

  factory PointBalance.fromJson(Map<String, dynamic> json) {
    final raw = json['recent'] as List<dynamic>? ?? const [];
    return PointBalance(
      balance: (json['points_balance'] as num? ?? 0).round(),
      recent: [
        for (final item in raw)
          PointLedgerEntry.fromJson(item as Map<String, dynamic>),
      ],
    );
  }
}
