import 'package:flutter/foundation.dart';
import 'package:rijiki/core/enums/order_payment_status.dart';
import 'package:rijiki/core/enums/order_status.dart';

@immutable
class OrderItemSummary {
  const OrderItemSummary({required this.shoeName, required this.serviceName});

  final String shoeName;
  final String serviceName;
}

@immutable
class CustomerOrder {
  const CustomerOrder({
    required this.id,
    required this.orderNumber,
    required this.status,
    required this.paymentStatus,
    required this.items,
    required this.totalPrice,
    required this.createdAt,
  });

  final String id;
  final String orderNumber;
  final OrderStatus status;
  final OrderPaymentStatus paymentStatus;
  final List<OrderItemSummary> items;
  final int totalPrice;
  final DateTime createdAt;

  String get serviceSummary =>
      items.map((item) => item.serviceName).toSet().join(', ');
}
