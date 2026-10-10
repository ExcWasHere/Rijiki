import 'package:flutter/foundation.dart';
import 'package:rijiki/core/enums/order_status.dart';
import 'package:rijiki/features/order/domain/customer_order.dart';

/// Ringkasan order untuk daftar "Order terbaru" di dashboard Owner.
///
/// Dipisah dari [CustomerOrder] supaya dashboard hanya membawa field yang
/// ditampilkan (bukan item, riwayat status, dokumentasi, dst). Data asli
/// cukup dipetakan lewat [RecentOrder.fromCustomerOrder].
@immutable
class RecentOrder {
  const RecentOrder({
    required this.id,
    required this.orderNumber,
    required this.customerName,
    required this.itemCount,
    required this.total,
    required this.status,
    required this.createdAt,
  });

  factory RecentOrder.fromCustomerOrder(CustomerOrder order) {
    return RecentOrder(
      id: order.id,
      orderNumber: order.orderNumber,
      customerName: order.customerName ?? 'Pelanggan',
      itemCount: order.shoeCount,
      total: order.totalPrice,
      status: order.status,
      createdAt: order.createdAt,
    );
  }

  final String id;
  final String orderNumber;
  final String customerName;

  /// Jumlah sepatu (bukan jumlah baris layanan), sama dengan
  /// [CustomerOrder.shoeCount].
  final int itemCount;

  /// Total bayar dalam rupiah, sama dengan [CustomerOrder.totalPrice].
  final int total;

  final OrderStatus status;
  final DateTime createdAt;
}
