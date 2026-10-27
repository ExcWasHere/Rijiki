import 'package:rijiki/core/enums/order_payment_status.dart';
import 'package:rijiki/core/enums/order_status.dart';
import 'package:rijiki/core/network/api_client.dart' show Json;
import 'package:rijiki/features/order/domain/customer_order.dart';
import 'package:rijiki/features/order/domain/order_documentation.dart';
import 'package:rijiki/features/order/domain/order_item.dart';
import 'package:rijiki/features/order/domain/order_status_history.dart';
import 'package:rijiki/features/order/domain/price_breakdown.dart';

CustomerOrder customerOrderFromJson(Json json) {
  final items = [
    for (final raw in json['items'] as List<dynamic>? ?? const [])
      _itemFromJson(raw as Json),
  ];
  final history = [
    for (final raw in json['status_history'] as List<dynamic>? ?? const [])
      _historyFromJson(raw as Json),
  ];
  final documentation = [
    for (final raw in json['documentation'] as List<dynamic>? ?? const [])
      _documentationFromJson(raw as Json),
  ];

  return CustomerOrder(
    id: json['id'] as String,
    orderNumber: json['order_number'] as String,
    status: OrderStatus.fromJson(json['status'] as String),
    paymentStatus: OrderPaymentStatus.fromJson(json['payment_status'] as String),
    items: items,
    price: PriceBreakdown(
      subtotal: _int(json['subtotal']),
      discount: _int(json['discount_amount']),
      shipping: _int(json['shipping_fee']),
    ),
    pickupAddress: json['pickup_address'] as String? ?? '',
    deliveryAddress: json['delivery_address'] as String? ?? '',
    createdAt: _date(json['created_at']) ?? DateTime.now(),
    scheduledPickupAt: _date(json['scheduled_pickup_at']),
    completedAt: _date(json['completed_at']),
    workerName: json['worker_name'] as String?,
    promoCode: json['promo_code'] as String?,
    customerName: json['customer_name'] as String?,
    customerPhone: json['customer_phone'] as String?,
    statusHistory: history,
    documentation: documentation,
    isRated: json['is_rated'] as bool? ?? false,
  );
}

OrderItem _itemFromJson(Json json) {
  return OrderItem(
    id: json['id'] as String,
    itemCode: json['item_code'] as String?,
    shoeName: json['shoe_name'] as String? ?? '-',
    serviceName: json['service_name'] as String? ?? '-',
    price: _int(json['price']),
    quantity: _int(json['quantity'], fallback: 1),
    notes: json['notes'] as String?,
  );
}

OrderStatusHistory _historyFromJson(Json json) {
  return OrderStatusHistory(
    status: OrderStatus.fromJson(json['status'] as String),
    changedAt: _date(json['changed_at']) ?? DateTime.now(),
    note: json['note'] as String?,
  );
}

OrderDocumentation _documentationFromJson(Json json) {
  final rawUrl = json['image_url'] as String?;
  return OrderDocumentation(
    id: json['id'] as String,
    type: _documentationType(json['type'] as String?),
    orderItemId: json['order_item_id'] as String?,
    photoUrl: rawUrl != null && rawUrl.startsWith('http') ? rawUrl : null,
  );
}

DocumentationType _documentationType(String? value) {
  return switch (value) {
    'after' => DocumentationType.after,
    'proof_of_delivery' => DocumentationType.proofOfDelivery,
    _ => DocumentationType.before,
  };
}

int _int(Object? value, {int fallback = 0}) {
  if (value is num) return value.round();
  return fallback;
}

DateTime? _date(Object? value) {
  if (value is! String || value.isEmpty) return null;
  return DateTime.tryParse(value)?.toLocal();
}
