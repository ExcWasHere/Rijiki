import 'package:flutter/material.dart';
import 'package:rijiki/core/enums/event_type.dart';
import 'package:rijiki/core/enums/order_status.dart';
import 'package:rijiki/core/theme/app_colors.dart';

extension OrderStatusUi on OrderStatus {
  String get label => switch (this) {
        OrderStatus.order => 'Order diterima',
        OrderStatus.pickup => 'Penjemputan',
        OrderStatus.waiting => 'Menunggu antrean',
        OrderStatus.cleaning => 'Dikerjakan',
        OrderStatus.delivery => 'Pengantaran',
        OrderStatus.completed => 'Selesai',
        OrderStatus.cancelled => 'Dibatalkan',
      };

  String get hint => switch (this) {
        OrderStatus.order => 'Pesananmu sudah kami terima, tinggal dijemput.',
        OrderStatus.pickup => 'Kurir sedang menuju lokasimu.',
        OrderStatus.waiting => 'Sepatu sudah di outlet, menunggu giliran.',
        OrderStatus.cleaning => 'Sepatumu sedang dikerjakan.',
        OrderStatus.delivery => 'Sepatu sedang diantar ke alamatmu.',
        OrderStatus.completed => 'Pesanan selesai. Terima kasih!',
        OrderStatus.cancelled => 'Pesanan ini dibatalkan.',
      };

  Color get color => switch (this) {
        OrderStatus.order => AppColors.info,
        OrderStatus.pickup => AppColors.rijikiBlue,
        OrderStatus.waiting => AppColors.warning,
        OrderStatus.cleaning => AppColors.primaryDark,
        OrderStatus.delivery => AppColors.rijikiOrange,
        OrderStatus.completed => AppColors.success,
        OrderStatus.cancelled => AppColors.error,
      };

  IconData get icon => switch (this) {
        OrderStatus.order => Icons.receipt_long_rounded,
        OrderStatus.pickup => Icons.two_wheeler_rounded,
        OrderStatus.waiting => Icons.hourglass_top_rounded,
        OrderStatus.cleaning => Icons.cleaning_services_rounded,
        OrderStatus.delivery => Icons.local_shipping_rounded,
        OrderStatus.completed => Icons.check_circle_rounded,
        OrderStatus.cancelled => Icons.cancel_rounded,
      };

  int get progressStep => switch (this) {
        OrderStatus.order => 0,
        OrderStatus.pickup => 1,
        OrderStatus.waiting => 2,
        OrderStatus.cleaning => 3,
        OrderStatus.delivery => 4,
        OrderStatus.completed => 5,
        OrderStatus.cancelled => -1,
      };

  static const int progressStepCount = 6;
}

extension EventTypeUi on EventType {
  String get label => switch (this) {
        EventType.promo => 'Promo',
        EventType.collaboration => 'Kolaborasi',
        EventType.announcement => 'Info',
      };

  Color get accent => switch (this) {
        EventType.promo => AppColors.rijikiOrange,
        EventType.collaboration => AppColors.primaryDark,
        EventType.announcement => AppColors.onSurfaceVariant,
      };

  Color get tint => switch (this) {
        EventType.promo => const Color(0xFFFFF1E6),
        EventType.collaboration => const Color(0xFFE6F6FD),
        EventType.announcement => const Color(0xFFEAF1F4),
      };
}
