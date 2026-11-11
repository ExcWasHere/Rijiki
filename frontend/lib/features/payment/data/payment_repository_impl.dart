import 'package:rijiki/core/constants/app_strings.dart';
import 'package:rijiki/core/enums/payment_status.dart';
import 'package:rijiki/core/error/app_exception.dart';
import 'package:rijiki/core/error/failure.dart';
import 'package:rijiki/core/network/api_client.dart';
import 'package:rijiki/core/network/api_endpoint.dart';
import 'package:rijiki/features/payment/domain/payment.dart';
import 'package:rijiki/features/payment/domain/payment_repository.dart';

Payment paymentFromJson(Json json) {
  return Payment(
    id: json['id'] as String,
    orderId: json['order_id'] as String,
    orderNumber: json['order_number'] as String,
    amount: (json['amount'] as num).round(),
    qrPayload: json['qr_payload'] as String? ?? '',
    status: PaymentStatus.fromJson(json['status'] as String),
    createdAt: DateTime.parse(json['created_at'] as String).toLocal(),
    expiresAt: DateTime.parse(json['expires_at'] as String).toLocal(),
  );
}

class PaymentRepositoryImpl implements PaymentRepository {
  PaymentRepositoryImpl({required this.api});

  final ApiClient api;

  @override
  Future<Payment> createPayment(String orderId) async {
    try {
      final json = await api.post(
        ApiEndpoints.orderPayment(orderId),
        auth: true,
      );
      return paymentFromJson(json);
    } on AppException catch (e) {
      throw _toFailure(e);
    }
  }

  @override
  Future<Payment> fetchStatus(String paymentId) async {
    try {
      final json = await api.get(ApiEndpoints.paymentById(paymentId), auth: true);
      return paymentFromJson(json);
    } on AppException catch (e) {
      throw _toFailure(e);
    }
  }

  Failure _toFailure(AppException e) {
    switch (e.code) {
      case AppException.networkCode:
      case AppException.offlineCode:
      case AppException.timeoutCode:
        return Failure(FailureType.network, e.message, code: e.code);
      case 'unauthorized':
        return Failure(FailureType.unauthorized, e.message, code: e.code);
      case 'rate_limited':
        return Failure(FailureType.rateLimited, e.message, code: e.code);
      case 'already_paid':
      case 'order_cancelled':
      case 'payment_in_progress':
        return Failure(FailureType.conflict, e.message, code: e.code);
    }
    if ((e.statusCode ?? 0) >= 500) {
      return Failure(FailureType.server, e.message, code: e.code);
    }
    return Failure(
      FailureType.unknown,
      e.message.isEmpty ? AppStrings.errUnknown : e.message,
      code: e.code,
    );
  }
}
