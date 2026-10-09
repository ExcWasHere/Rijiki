import 'package:flutter/foundation.dart';
import 'package:rijiki/core/enums/payment_status.dart';

@immutable
class Payment {
  const Payment({
    required this.id,
    required this.orderId,
    required this.orderNumber,
    required this.amount,
    required this.qrPayload,
    required this.status,
    required this.createdAt,
    required this.expiresAt,
  });

  final String id;
  final String orderId;
  final String orderNumber;
  final int amount;
  final String qrPayload;
  final PaymentStatus status;
  final DateTime createdAt;
  final DateTime expiresAt;

  Duration get lifetime => expiresAt.difference(createdAt);

  Payment copyWith({PaymentStatus? status}) {
    return Payment(
      id: id,
      orderId: orderId,
      orderNumber: orderNumber,
      amount: amount,
      qrPayload: qrPayload,
      status: status ?? this.status,
      createdAt: createdAt,
      expiresAt: expiresAt,
    );
  }
}
