import 'package:rijiki/core/enums/order_payment_status.dart';
import 'package:rijiki/core/enums/order_status.dart';
import 'package:rijiki/core/mock/mock_scenario.dart';
import 'package:rijiki/features/order/domain/customer_order.dart';
import 'package:rijiki/features/order/domain/order_repository.dart';

class MockOrderRepository implements OrderRepository {
  const MockOrderRepository({this.scenario = MockScenario.data});

  final MockScenario scenario;

  @override
  Future<List<CustomerOrder>> fetchActiveOrders() {
    final now = DateTime.now();
    return scenario.resolve<List<CustomerOrder>>(
      empty: const [],
      data: [
        CustomerOrder(
          id: 'ord-1',
          orderNumber: 'RJK-0710-002',
          status: OrderStatus.cleaning,
          paymentStatus: OrderPaymentStatus.paid,
          items: const [
            OrderItemSummary(shoeName: 'Nike Air Force 1', serviceName: 'Deep Clean'),
            OrderItemSummary(shoeName: 'Adidas Samba', serviceName: 'Fast Clean'),
          ],
          totalPrice: 75000,
          createdAt: now.subtract(const Duration(days: 1)),
        ),
        CustomerOrder(
          id: 'ord-2',
          orderNumber: 'RJK-0710-005',
          status: OrderStatus.order,
          paymentStatus: OrderPaymentStatus.unpaid,
          items: const [
            OrderItemSummary(shoeName: 'Sandal Eiger', serviceName: 'Cuci Sandal'),
          ],
          totalPrice: 18000,
          createdAt: now.subtract(const Duration(hours: 2)),
        ),
      ],
    );
  }
}
