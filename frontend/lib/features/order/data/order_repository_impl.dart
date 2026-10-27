import 'package:rijiki/core/constants/app_strings.dart';
import 'package:rijiki/core/enums/order_payment_status.dart';
import 'package:rijiki/core/error/app_exception.dart';
import 'package:rijiki/core/error/failure.dart';
import 'package:rijiki/core/network/api_client.dart';
import 'package:rijiki/core/network/api_endpoint.dart';
import 'package:rijiki/features/order/data/mock_order_store.dart';
import 'package:rijiki/features/order/data/order_mapper.dart';
import 'package:rijiki/features/order/domain/customer_order.dart';
import 'package:rijiki/features/order/domain/new_order.dart';
import 'package:rijiki/features/order/domain/order_repository.dart';
import 'package:rijiki/features/order/domain/price_breakdown.dart';
import 'package:rijiki/features/order/domain/price_quote.dart';

class OrderRepositoryImpl implements OrderRepository {
  OrderRepositoryImpl({required this.api});

  final ApiClient api;

  static const int _listLimit = 50;
  static const int _activeLimit = 2;

  @override
  Future<List<CustomerOrder>> fetchOrders() {
    return _fetchList({'page': '1', 'limit': '$_listLimit'});
  }

  @override
  Future<List<CustomerOrder>> fetchActiveOrders() {
    return _fetchList({'active': 'true', 'page': '1', 'limit': '$_activeLimit'});
  }

  @override
  Future<CustomerOrder> fetchOrderById(String id) async {
    try {
      final json = await api.get(ApiEndpoints.orderById(id), auth: true);
      return _withMockPayment(customerOrderFromJson(json));
    } on AppException catch (e) {
      throw _toFailure(e);
    }
  }

  @override
  Future<PriceQuote> quotePrice({
    required int subtotal,
    String? promoCode,
  }) async {
    final code = promoCode?.trim() ?? '';
    try {
      final json = await api.post(
        ApiEndpoints.orderQuote,
        auth: true,
        body: {'subtotal': subtotal, if (code.isNotEmpty) 'promo_code': code},
      );
      return PriceQuote(
        price: PriceBreakdown(
          subtotal: (json['subtotal'] as num).round(),
          discount: (json['discount_amount'] as num).round(),
          shipping: (json['shipping_fee'] as num).round(),
        ),
        promoCode: json['promo_code'] as String?,
        promoDescription: json['promo_description'] as String?,
      );
    } on AppException catch (e) {
      if (e.code == 'promo_invalid') throw PromoException(e.message);
      throw _toFailure(e);
    }
  }

  @override
  Future<CustomerOrder> createOrder(NewOrder order, PriceQuote quote) async {
    try {
      final json = await api.post(
        ApiEndpoints.orders,
        auth: true,
        body: {
          'items': [
            for (final item in order.items)
              {
                'service_id': item.service!.id,
                'shoe_brand': item.shoeBrand.trim(),
                'quantity': item.quantity,
                if (item.notes.trim().isNotEmpty) 'notes': item.notes.trim(),
              },
          ],
          'pickup_address': order.pickupAddress,
          'delivery_address': order.deliveryAddress,
          if (order.promoCode != null) 'promo_code': order.promoCode,
        },
      );
      return customerOrderFromJson(json);
    } on AppException catch (e) {
      if (e.code == 'promo_invalid') throw Failure(FailureType.validation, e.message, code: e.code);
      throw _toFailure(e);
    }
  }

  Future<List<CustomerOrder>> _fetchList(Map<String, String> query) async {
    try {
      final path = Uri(
        path: ApiEndpoints.orders,
        queryParameters: query,
      ).toString();
      final json = await api.get(path, auth: true);
      final raw = json['items'] as List<dynamic>? ?? const [];
      return [
        for (final item in raw)
          _withMockPayment(customerOrderFromJson(item as Json)),
      ];
    } on AppException catch (e) {
      throw _toFailure(e);
    }
  }

  // TODO(tahap-B): hapus overlay ini begitu pembayaran QRIS Duitku asli
  // terhubung. Selama QRIS masih mock, "lunas" hanya hidup di memori aplikasi
  // (MockOrderStore) dan tidak pernah ditulis ke backend.
  CustomerOrder _withMockPayment(CustomerOrder order) {
    if (!order.isPaid && MockOrderStore.paidOrderIds.contains(order.id)) {
      return order.copyWith(paymentStatus: OrderPaymentStatus.paid);
    }
    return order;
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
      case 'validation_error':
      case 'profile_incomplete':
      case 'service_unavailable':
        return Failure(FailureType.validation, e.message, code: e.code);
      case 'price_changed':
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
