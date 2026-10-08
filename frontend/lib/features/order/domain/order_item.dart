import 'package:flutter/foundation.dart';

@immutable
class OrderItem {
  const OrderItem({
    required this.id,
    required this.shoeName,
    required this.serviceName,
    required this.price,
    this.quantity = 1,
    this.notes,
  });

  final String id;

  final String shoeName;
  final String serviceName;

  final int price;
  final int quantity;

  final String? notes;

  int get lineTotal => price * quantity;
}
