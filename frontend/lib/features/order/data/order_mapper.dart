import 'package:rijiki/core/enums/order_payment_status.dart';
import 'package:rijiki/core/enums/order_status.dart';
import 'package:rijiki/core/network/api_client.dart' show Json;
import 'package:rijiki/features/order/domain/assignable_worker.dart';
import 'package:rijiki/features/order/domain/customer_order.dart';
import 'package:rijiki/features/order/domain/delivery_method.dart';
import 'package:rijiki/features/order/domain/order_documentation.dart';
import 'package:rijiki/features/order/domain/order_item.dart';
import 'package:rijiki/features/order/domain/order_status_history.dart';
import 'package:rijiki/features/order/domain/price_breakdown.dart';
import 'package:rijiki/features/order/domain/staff_capabilities.dart';

/// Memetakan JSON backend (`/api/orders`) ke entity domain.
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
      orderDocumentationFromJson(raw as Json),
  ];
  final staff = json['staff'];

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
    deliveryMethod: DeliveryMethod.fromJson(json['delivery_method'] as String?),
    isOffline: json['channel'] == 'staff_manual',
    assignedWorkerId: json['assigned_worker_id'] as String?,
    assignedToMe: json['assigned_to_me'] as bool? ?? false,
    staff: staff is Map<String, dynamic> ? _capabilitiesFromJson(staff) : null,
  );
}

OrderDocumentation orderDocumentationFromJson(Json json) {
  final raw = json['image_url'] as String?;
  final isUrl = raw != null && raw.startsWith('http');
  return OrderDocumentation(
    id: json['id'] as String,
    type: DocumentationType.fromJson(json['type'] as String?),
    orderItemId: json['order_item_id'] as String?,
    photoUrl: isUrl ? raw : null,
    imageKey: isUrl ? null : raw,
  );
}

AssignableWorker assignableWorkerFromJson(Json json) {
  return AssignableWorker(
    id: json['id'] as String,
    fullName: json['full_name'] as String? ?? '-',
    employeeCode: json['employee_code'] as String? ?? '',
    division: json['division'] as String? ?? '',
    avatarUrl: json['avatar_url'] as String?,
  );
}

StaffCapabilities _capabilitiesFromJson(Json json) {
  final next = json['next_status'] as String?;
  final upload = json['can_upload'];
  final uploadMap = upload is Map<String, dynamic> ? upload : const <String, dynamic>{};

  return StaffCapabilities(
    nextStatus: next == null ? null : OrderStatus.fromJson(next),
    canClaim: json['can_claim'] as bool? ?? false,
    canAdvance: json['can_advance'] as bool? ?? false,
    canAssign: json['can_assign'] as bool? ?? false,
    canCancel: json['can_cancel'] as bool? ?? false,
    canCorrect: json['can_correct'] as bool? ?? false,
    canUpload: {
      for (final type in DocumentationType.values)
        if (uploadMap[type.json] == true) type,
    },
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

int _int(Object? value, {int fallback = 0}) {
  if (value is num) return value.round();
  return fallback;
}

DateTime? _date(Object? value) {
  if (value is! String || value.isEmpty) return null;
  return DateTime.tryParse(value)?.toLocal();
}
