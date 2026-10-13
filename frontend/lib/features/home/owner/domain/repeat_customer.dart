import 'package:flutter/foundation.dart';

@immutable
class RepeatCustomer {
  const RepeatCustomer({
    required this.id,
    required this.name,
    required this.completedOrders,
    required this.totalSpent,
    this.avatarUrl,
  });

  final String id;
  final String name;
  final String? avatarUrl;
  final int completedOrders;
  final double totalSpent;
}
