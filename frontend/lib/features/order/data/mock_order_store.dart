import 'package:rijiki/core/enums/order_payment_status.dart';
import 'package:rijiki/features/order/domain/customer_order.dart';

abstract final class MockOrderStore {
  static final List<CustomerOrder> created = [];
  static final Set<String> paidOrderIds = {};
  static int _sequence = 20;

  static int nextSequence() => ++_sequence;
  static void markPaid(String orderId) => paidOrderIds.add(orderId);
  static List<CustomerOrder> apply(List<CustomerOrder> base) {
    return [...created, ...base]
        .map(
          (order) => paidOrderIds.contains(order.id) && !order.isPaid
              ? order.copyWith(paymentStatus: OrderPaymentStatus.paid)
              : order,
        )
        .toList();
  }
}
