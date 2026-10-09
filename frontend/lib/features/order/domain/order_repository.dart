import 'package:rijiki/features/order/domain/customer_order.dart';
import 'package:rijiki/features/order/domain/new_order.dart';
import 'package:rijiki/features/order/domain/price_quote.dart';

abstract interface class OrderRepository {
  Future<List<CustomerOrder>> fetchOrders();
  Future<List<CustomerOrder>> fetchActiveOrders();
  Future<CustomerOrder> fetchOrderById(String id);
  Future<PriceQuote> quotePrice({required int subtotal, String? promoCode});
  Future<CustomerOrder> createOrder(NewOrder order, PriceQuote quote);
}
