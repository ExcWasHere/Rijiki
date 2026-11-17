import 'package:flutter/foundation.dart';

enum AppNotificationType {
  orderStatus('order_status'),
  orderAssigned('order_assigned'),
  paymentPaid('payment_paid'),
  pointRedemption('point_redemption'),
  unknown('unknown');

  const AppNotificationType(this.value);

  final String value;

  static AppNotificationType fromJson(String? value) {
    return AppNotificationType.values.firstWhere(
      (type) => type.value == value,
      orElse: () => AppNotificationType.unknown,
    );
  }
}

@immutable
class AppNotification {
  const AppNotification({
    required this.id,
    required this.type,
    required this.title,
    required this.body,
    required this.read,
    required this.createdAt,
    this.data = const {},
  });

  final String id;
  final AppNotificationType type;
  final String title;
  final String body;
  final bool read;
  final DateTime createdAt;

  /// Data tambahan dari backend, mis. `order_id` untuk membuka detail order.
  final Map<String, dynamic> data;

  String? get orderId => data['order_id'] as String?;

  AppNotification copyWith({bool? read}) {
    return AppNotification(
      id: id,
      type: type,
      title: title,
      body: body,
      read: read ?? this.read,
      createdAt: createdAt,
      data: data,
    );
  }

  factory AppNotification.fromJson(Map<String, dynamic> json) {
    final rawData = json['data'];
    return AppNotification(
      id: json['id'] as String,
      type: AppNotificationType.fromJson(json['type'] as String?),
      title: json['title'] as String? ?? '',
      body: json['body'] as String? ?? '',
      read: json['read'] == true,
      createdAt:
          DateTime.tryParse(json['created_at'] as String? ?? '') ??
          DateTime.now(),
      data: rawData is Map<String, dynamic> ? rawData : const {},
    );
  }
}

@immutable
class NotificationPage {
  const NotificationPage({
    required this.items,
    required this.total,
    required this.unread,
  });

  final List<AppNotification> items;
  final int total;
  final int unread;
}
