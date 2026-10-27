import 'package:flutter/foundation.dart';
import 'package:rijiki/core/enums/order_payment_status.dart';
import 'package:rijiki/core/enums/order_status.dart';
import 'package:rijiki/features/order/domain/delivery_method.dart';
import 'package:rijiki/features/order/domain/order_documentation.dart';
import 'package:rijiki/features/order/domain/order_item.dart';
import 'package:rijiki/features/order/domain/order_status_history.dart';
import 'package:rijiki/features/order/domain/price_breakdown.dart';
import 'package:rijiki/features/order/domain/staff_capabilities.dart';

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
    this.customerName,
    this.customerPhone,
    this.statusHistory = const [],
    this.documentation = const [],
    this.isRated = false,
    this.deliveryMethod = DeliveryMethod.delivery,
    this.isOffline = false,
    this.assignedWorkerId,
    this.assignedToMe = false,
    this.staff,
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
  final String? customerName;
  final String? customerPhone;
  final List<OrderStatusHistory> statusHistory;
  final List<OrderDocumentation> documentation;
  final bool isRated;
  final DeliveryMethod deliveryMethod;
  final bool isOffline;
  final String? assignedWorkerId;
  final bool assignedToMe;
  final StaffCapabilities? staff;

  int get totalPrice => price.total;
  int get shoeCount => items.fold(0, (sum, item) => sum + item.quantity);

  String get shoeNames => items.map((item) => item.shoeName).toSet().join(', ');
  String get serviceSummary =>
      items.map((item) => item.serviceName).toSet().join(', ');

  bool get isPaid => paymentStatus == OrderPaymentStatus.paid;

  bool get canPay => !isPaid && status != OrderStatus.cancelled;

  bool get canRate => status == OrderStatus.completed && !isRated;
  List<OrderStatus> get flowStatuses {
    if (!isOffline) {
      return const [
        OrderStatus.order,
        OrderStatus.pickup,
        OrderStatus.waiting,
        OrderStatus.cleaning,
        OrderStatus.delivery,
        OrderStatus.completed,
      ];
    }
    return deliveryMethod == DeliveryMethod.selfPickup
        ? const [OrderStatus.waiting, OrderStatus.cleaning, OrderStatus.completed]
        : const [
            OrderStatus.waiting,
            OrderStatus.cleaning,
            OrderStatus.delivery,
            OrderStatus.completed,
          ];
  }

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
      customerName: customerName,
      customerPhone: customerPhone,
      statusHistory: statusHistory,
      documentation: documentation,
      isRated: isRated,
      deliveryMethod: deliveryMethod,
      isOffline: isOffline,
      assignedWorkerId: assignedWorkerId,
      assignedToMe: assignedToMe,
      staff: staff,
    );
  }

  DateTime? timeOf(OrderStatus target) {
    for (final entry in statusHistory) {
      if (entry.status == target) return entry.changedAt;
    }
    return null;
  }
}
