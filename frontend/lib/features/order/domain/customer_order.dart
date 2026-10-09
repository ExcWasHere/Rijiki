import 'package:flutter/foundation.dart';
import 'package:rijiki/core/enums/order_payment_status.dart';
import 'package:rijiki/core/enums/order_status.dart';
import 'package:rijiki/features/order/domain/order_documentation.dart';
import 'package:rijiki/features/order/domain/order_item.dart';
import 'package:rijiki/features/order/domain/order_status_history.dart';
import 'package:rijiki/features/order/domain/price_breakdown.dart';

@immutable
class CustomerOrder {
  const CustomerOrder({
    required this.id,
    required this.orderNumber,
    required this.status,
    required this.paymentStatus,
    required this.items,
    required this.price,
    required this.pickupAddress,
    required this.deliveryAddress,
    required this.createdAt,
    this.scheduledPickupAt,
    this.completedAt,
    this.workerName,
    this.promoCode,
    this.statusHistory = const [],
    this.documentation = const [],
    this.isRated = false,
  });

  final String id;
  final String orderNumber;
  final OrderStatus status;
  final OrderPaymentStatus paymentStatus;
  final List<OrderItem> items;
  final PriceBreakdown price;
  final String pickupAddress;
  final String deliveryAddress;
  final DateTime createdAt;
  final DateTime? scheduledPickupAt;
  final DateTime? completedAt;
  final String? workerName;
  final String? promoCode;
  final List<OrderStatusHistory> statusHistory;
  final List<OrderDocumentation> documentation;
  final bool isRated;

  int get totalPrice => price.total;
  int get shoeCount {
    final perShoe = <String, int>{};
    for (final item in items) {
      final current = perShoe[item.shoeName] ?? 0;
      if (item.quantity > current) perShoe[item.shoeName] = item.quantity;
    }
    return perShoe.values.fold(0, (sum, count) => sum + count);
  }

  String get shoeNames => items.map((item) => item.shoeName).toSet().join(', ');
  String get serviceSummary =>
      items.map((item) => item.serviceName).toSet().join(', ');

  bool get isPaid => paymentStatus == OrderPaymentStatus.paid;

  bool get canPay => !isPaid && status != OrderStatus.cancelled;

  bool get canRate => status == OrderStatus.completed && !isRated;

  CustomerOrder copyWith({OrderPaymentStatus? paymentStatus}) {
    return CustomerOrder(
      id: id,
      orderNumber: orderNumber,
      status: status,
      paymentStatus: paymentStatus ?? this.paymentStatus,
      items: items,
      price: price,
      pickupAddress: pickupAddress,
      deliveryAddress: deliveryAddress,
      createdAt: createdAt,
      scheduledPickupAt: scheduledPickupAt,
      completedAt: completedAt,
      workerName: workerName,
      promoCode: promoCode,
      statusHistory: statusHistory,
      documentation: documentation,
      isRated: isRated,
    );
  }

  DateTime? timeOf(OrderStatus target) {
    for (final entry in statusHistory) {
      if (entry.status == target) return entry.changedAt;
    }
    return null;
  }
}
