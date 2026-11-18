import 'package:rijiki/core/error/app_exception.dart';
import 'package:rijiki/core/error/failure_mapper.dart';
import 'package:rijiki/core/network/api_client.dart';
import 'package:rijiki/core/network/api_endpoint.dart';
import 'package:rijiki/features/chat/domain/order_chat_repository.dart';
import 'package:rijiki/features/chat/domain/order_message.dart';

/// Chat order dari backend (`/api/orders/:id/messages`). Hak akses mengikuti
/// aturan order: customer pemilik, worker penangan, dan owner.
class OrderChatRepositoryImpl implements OrderChatRepository {
  OrderChatRepositoryImpl({required this.api});

  final ApiClient api;

  @override
  Future<OrderThread> fetchThread(String orderId) async {
    try {
      final json = await api.get(
        ApiEndpoints.orderMessages(orderId),
        auth: true,
      );
      return OrderThread(
        messages: [
          for (final raw in json['items'] as List<dynamic>? ?? const [])
            OrderMessage.fromJson(raw as Map<String, dynamic>),
        ],
        unread: (json['unread'] as num? ?? 0).round(),
      );
    } on AppException catch (e) {
      throw failureFromException(e);
    }
  }

  @override
  Future<OrderMessage> send(String orderId, String body) async {
    try {
      final json = await api.post(
        ApiEndpoints.orderMessages(orderId),
        auth: true,
        body: {'body': body},
      );
      return OrderMessage.fromJson(json);
    } on AppException catch (e) {
      throw failureFromException(e);
    }
  }

  @override
  Future<void> markRead(String orderId) async {
    try {
      await api.post(ApiEndpoints.orderMessagesRead(orderId), auth: true);
    } on AppException catch (e) {
      throw failureFromException(e);
    }
  }
}
