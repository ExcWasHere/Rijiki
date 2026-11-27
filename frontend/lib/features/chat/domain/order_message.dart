import 'package:flutter/foundation.dart';

/// Pengirim pesan chat order.
enum MessageSenderRole {
  customer('customer'),
  worker('worker'),
  owner('owner');

  const MessageSenderRole(this.value);

  final String value;

  static MessageSenderRole fromJson(String? value) {
    return MessageSenderRole.values.firstWhere(
      (role) => role.value == value,
      orElse: () => MessageSenderRole.worker,
    );
  }

  String get label => switch (this) {
    MessageSenderRole.customer => 'Customer',
    MessageSenderRole.worker => 'Kurir',
    MessageSenderRole.owner => 'Owner',
  };
}

@immutable
class OrderMessage {
  const OrderMessage({
    required this.id,
    required this.orderId,
    required this.senderId,
    required this.senderRole,
    required this.body,
    required this.createdAt,
    required this.mine,
  });

  final String id;
  final String orderId;
  final String senderId;
  final MessageSenderRole senderRole;
  final String body;
  final DateTime createdAt;

  /// true bila pesan dikirim oleh pengguna yang sedang login.
  final bool mine;

  factory OrderMessage.fromJson(Map<String, dynamic> json) {
    return OrderMessage(
      id: json['id'] as String,
      orderId: json['order_id'] as String? ?? '',
      senderId: json['sender_id'] as String? ?? '',
      senderRole: MessageSenderRole.fromJson(json['sender_role'] as String?),
      body: json['body'] as String? ?? '',
      createdAt:
          DateTime.tryParse(json['created_at'] as String? ?? '') ??
          DateTime.now(),
      mine: json['mine'] as bool? ?? false,
    );
  }
}

@immutable
class OrderThread {
  const OrderThread({required this.messages, required this.unread});

  final List<OrderMessage> messages;

  /// Pesan dari lawan bicara yang belum dibaca.
  final int unread;

  static const OrderThread empty = OrderThread(messages: [], unread: 0);
}
