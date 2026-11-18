import 'package:flutter/foundation.dart';

@immutable
class RepeatCustomer {
  const RepeatCustomer({
    required this.id,
    required this.name,
    required this.completedOrders,
    required this.totalSpent,
    this.avatarUrl,
    this.phone,
    this.lastOrderAt,
    this.hasAccount = true,
  });

  final String id;
  final String name;
  final String? avatarUrl;
  final int completedOrders;
  final double totalSpent;

  /// Nomor HP pelanggan (dari akun, atau dari order offline).
  final String? phone;
  final DateTime? lastOrderAt;

  /// false = pelanggan offline yang belum punya akun.
  final bool hasAccount;

  factory RepeatCustomer.fromJson(Map<String, dynamic> json) {
    return RepeatCustomer(
      id: json['id'] as String,
      name: json['name'] as String? ?? 'Pelanggan',
      avatarUrl: json['avatar_url'] as String?,
      completedOrders: (json['completed_orders'] as num? ?? 0).round(),
      totalSpent: (json['total_spent'] as num? ?? 0).toDouble(),
      phone: json['phone'] as String?,
      lastOrderAt: DateTime.tryParse(json['last_order_at'] as String? ?? ''),
      hasAccount: json['has_account'] as bool? ?? true,
    );
  }
}
