import 'package:flutter/material.dart';
import 'package:rijiki/core/theme/app_colors.dart';
import 'package:rijiki/core/utils/date_formatter.dart';
import 'package:rijiki/features/notifications/domain/app_notification.dart';

extension AppNotificationTypeUi on AppNotificationType {
  IconData get icon => switch (this) {
    AppNotificationType.orderNew => Icons.add_shopping_cart_rounded,
    AppNotificationType.orderStatus => Icons.local_shipping_outlined,
    AppNotificationType.orderAssigned => Icons.assignment_ind_outlined,
    AppNotificationType.orderMessage => Icons.chat_bubble_outline_rounded,
    AppNotificationType.paymentPaid => Icons.payments_outlined,
    AppNotificationType.paymentExpired => Icons.timer_off_outlined,
    AppNotificationType.pointRedemption => Icons.redeem_outlined,
    AppNotificationType.pointRedemptionRequest => Icons.card_giftcard_rounded,
    AppNotificationType.unknown => Icons.notifications_none_rounded,
  };

  Color get color => switch (this) {
    AppNotificationType.orderNew => AppColors.primaryDark,
    AppNotificationType.orderStatus => AppColors.rijikiBlue,
    AppNotificationType.orderAssigned => AppColors.primaryDark,
    AppNotificationType.orderMessage => AppColors.rijikiBlue,
    AppNotificationType.paymentPaid => AppColors.success,
    AppNotificationType.paymentExpired => AppColors.onSurfaceVariant,
    AppNotificationType.pointRedemption => AppColors.rijikiOrange,
    AppNotificationType.pointRedemptionRequest => AppColors.rijikiOrange,
    AppNotificationType.unknown => AppColors.onSurfaceVariant,
  };
}

extension AppNotificationUi on AppNotification {
  /// Waktu ringkas: "Baru saja", "12 menit lalu", "3 jam lalu", lalu tanggal.
  String get timeLabel {
    final diff = DateTime.now().difference(createdAt);
    if (diff.inMinutes < 1) return 'Baru saja';
    if (diff.inMinutes < 60) return '${diff.inMinutes} menit lalu';
    if (diff.inHours < 24) return '${diff.inHours} jam lalu';
    if (diff.inDays < 7) return '${diff.inDays} hari lalu';
    return DateFormatter.shortDate(createdAt);
  }
}
