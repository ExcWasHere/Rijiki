import 'package:rijiki/core/enums/order_status.dart';
import 'package:rijiki/features/order/domain/assignable_worker.dart';
import 'package:rijiki/features/order/domain/customer_order.dart';
import 'package:rijiki/features/order/domain/order_documentation.dart';

enum StaffOrderList { primary, unassigned }

abstract interface class StaffOrderRepository {
  Future<List<CustomerOrder>> fetchOrders(StaffOrderList list);
  Future<CustomerOrder> fetchOrder(String id);
  Future<CustomerOrder> claim(String id);
  Future<CustomerOrder> assign(String id, String? workerId);

  Future<CustomerOrder> updateStatus(
    String id,
    OrderStatus status, {
    String? notes,
  });

  Future<OrderDocumentation> uploadDocumentation({
    required String orderId,
    required DocumentationType type,
    required String imagePath,
    String? orderItemId,
  });

  Future<void> deleteDocumentation({
    required String orderId,
    required String documentationId,
  });

  Future<List<AssignableWorker>> fetchAssignableWorkers();
}
