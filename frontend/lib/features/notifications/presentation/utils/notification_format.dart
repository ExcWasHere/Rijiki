import 'package:flutter/material.dart';
import 'package:rijiki/core/theme/app_colors.dart';
import 'package:rijiki/core/utils/date_formatter.dart';
import 'package:rijiki/features/notifications/domain/app_notification.dart';

extension AppNotificationTypeUi on AppNotificationType {
  IconData get icon => switch (this) {
    AppNotificationType.orderStatus => Icons.local_shipping_outlined,
    AppNotificationType.orderAssigned => Icons.assignment_ind_outlined,
    AppNotificationType.paymentPaid => Icons.payments_outlined,
    AppNotificationType.pointRedemption => Icons.redeem_outlined,
    AppNotificationType.unknown => Icons.notifications_none_rounded,
  };

  Color get color => switch (this) {
    AppNotificationType.orderStatus => AppColors.rijikiBlue,
    AppNotificationType.orderAssigned => AppColors.primaryDark,
    AppNotificationType.paymentPaid => AppColors.success,
    AppNotificationType.pointRedemption => AppColors.rijikiOrange,
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
