import 'package:flutter/foundation.dart';
import 'package:rijiki/features/service/domain/care_service.dart';

@immutable
class OrderDraftItem {
  const OrderDraftItem({
    required this.id,
    this.shoeBrand = '',
    this.quantity = 1,
    this.service,
    this.notes = '',
  });

  final String id;
  final String shoeBrand;
  final int quantity;
  final CareService? service;
  final String notes;

  int get lineTotal => (service?.basePrice ?? 0) * quantity;

  bool get isComplete =>
      shoeBrand.trim().isNotEmpty && service != null && quantity >= 1;

  OrderDraftItem copyWith({
    String? shoeBrand,
    int? quantity,
    CareService? service,
    String? notes,
  }) {
    return OrderDraftItem(
      id: id,
      shoeBrand: shoeBrand ?? this.shoeBrand,
      quantity: quantity ?? this.quantity,
      service: service ?? this.service,
      notes: notes ?? this.notes,
    );
  }
}

@immutable
class NewOrder {
  const NewOrder({
    required this.customerName,
    required this.phone,
    required this.items,
    required this.pickupAddress,
    required this.deliveryAddress,
    this.promoCode,
  });

  final String customerName;
  final String phone;
  final List<OrderDraftItem> items;
  final String pickupAddress;
  final String deliveryAddress;
  final String? promoCode;
}
