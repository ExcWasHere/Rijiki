import 'package:flutter/foundation.dart';
import 'package:rijiki/features/order/domain/delivery_method.dart';
import 'package:rijiki/features/order/domain/new_order.dart';

/// Metode bayar order offline. Nilai `json` = nilai enum di backend.
enum OfflinePaymentMethod {
  cash,
  qris;

  String get json => name;
  String get label => this == cash ? 'Tunai' : 'QRIS';
}

/// Order yang dicatat worker/owner untuk customer yang datang langsung ke
/// outlet (tanpa akun). Harga, promo, dan ongkir dihitung ulang server.
@immutable
class NewOfflineOrder {
  const NewOfflineOrder({
    required this.customerName,
    required this.phone,
    required this.items,
    required this.paymentMethod,
    this.deliveryMethod = DeliveryMethod.selfPickup,
    this.promoCode,
    this.assignedWorkerId,
    this.idempotencyKey,
  });

  final String customerName;
  final String phone;
  final List<OrderDraftItem> items;
  final OfflinePaymentMethod paymentMethod;
  final DeliveryMethod deliveryMethod;
  final String? promoCode;

  /// worker_profiles.id; null = worker yang login (owner: tanpa worker).
  final String? assignedWorkerId;

  /// Kunci per upaya simpan. Kirim ulang karena gagal jaringan memakai kunci
  /// yang sama sehingga order tidak terbuat dua kali.
  final String? idempotencyKey;
}
