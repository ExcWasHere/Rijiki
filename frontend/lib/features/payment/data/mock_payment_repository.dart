import 'package:rijiki/core/enums/payment_status.dart';
import 'package:rijiki/core/mock/mock_scenario.dart';
import 'package:rijiki/features/order/data/mock_order_store.dart';
import 'package:rijiki/features/order/domain/order_repository.dart';
import 'package:rijiki/features/payment/domain/payment.dart';
import 'package:rijiki/features/payment/domain/payment_repository.dart';

class MockPaymentRepository implements PaymentRepository {
  const MockPaymentRepository({
    required this.orders,
    this.scenario = MockScenario.data,
  });

  final OrderRepository orders;
  final MockScenario scenario;

  static const Duration lifetime = Duration(minutes: 15);
  static const Duration shortLifetime = Duration(seconds: 20);
  static const Duration paidAfter = Duration(seconds: 8);

  static final Map<String, Payment> _payments = {};

  @override
  Future<Payment> createPayment(String orderId) async {
    await scenario.resolve<bool>(empty: true, data: true);
    final order = await orders.fetchOrderById(orderId);

    final now = DateTime.now();
    final payment = Payment(
      id: 'pay-${now.microsecondsSinceEpoch}',
      orderId: order.id,
      orderNumber: order.orderNumber,
      amount: order.totalPrice,
      qrPayload: 'RIJIKI-MOCK-QRIS|${order.orderNumber}|${order.totalPrice}',
      status: PaymentStatus.pending,
      createdAt: now,
      expiresAt: now.add(
        scenario == MockScenario.empty ? shortLifetime : lifetime,
      ),
    );
    _payments[payment.id] = payment;
    return payment;
  }

  @override
  Future<Payment> fetchStatus(String paymentId) async {
    final payment = _payments[paymentId];
    if (payment == null) throw const MockException('Pembayaran tidak ditemukan');
    if (payment.status != PaymentStatus.pending) return payment;

    final now = DateTime.now();
    final elapsed = now.difference(payment.createdAt);

    PaymentStatus next = PaymentStatus.pending;
    if (scenario == MockScenario.data && elapsed >= paidAfter) {
      next = PaymentStatus.paid;
      MockOrderStore.markPaid(payment.orderId);
    } else if (now.isAfter(payment.expiresAt)) {
      next = PaymentStatus.expired;
    }

    final updated = payment.copyWith(status: next);
    _payments[paymentId] = updated;
    return updated;
  }
}
