import 'package:flutter/foundation.dart';
import 'package:rijiki/core/enums/order_status.dart';

@immutable
class OrderStatusHistory {
  const OrderStatusHistory({
    required this.status,
    required this.changedAt,
    this.note,
  });

  final OrderStatus status;
  final DateTime changedAt;
  final String? note;
}
