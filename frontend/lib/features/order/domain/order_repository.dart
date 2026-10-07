import 'package:rijiki/features/order/domain/customer_order.dart';

abstract interface class OrderRepository {
  Future<List<CustomerOrder>> fetchActiveOrders();
}
