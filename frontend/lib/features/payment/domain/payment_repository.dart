import 'package:rijiki/features/payment/domain/payment.dart';

abstract interface class PaymentRepository {
  Future<Payment> createPayment(String orderId);
  Future<Payment> fetchStatus(String paymentId);
}
