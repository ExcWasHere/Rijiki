import 'package:rijiki/features/chat/domain/order_message.dart';

/// Chat per order: customer, worker penangan, dan owner.
abstract interface class OrderChatRepository {
  Future<OrderThread> fetchThread(String orderId);

  Future<OrderMessage> send(String orderId, String body);

  Future<void> markRead(String orderId);
}
