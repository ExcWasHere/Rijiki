import 'package:rijiki/core/enums/order_status.dart';
import 'package:rijiki/core/error/failure.dart';
import 'package:rijiki/features/order/domain/assignable_worker.dart';
import 'package:rijiki/features/order/domain/customer_order.dart';
import 'package:rijiki/features/order/domain/order_documentation.dart';
import 'package:rijiki/features/order/domain/order_repository.dart';
import 'package:rijiki/features/order/domain/staff_order_repository.dart';

class MockStaffOrderRepository implements StaffOrderRepository {
  const MockStaffOrderRepository({required this.orders});

  final OrderRepository orders;

  static const String _needsBackend =
      'Aksi ini hanya tersedia saat terhubung ke backend.';

  Never _unsupported() =>
      throw const Failure(FailureType.unknown, _needsBackend);

  @override
  Future<List<CustomerOrder>> fetchOrders(StaffOrderList list) async {
    if (list == StaffOrderList.unassigned) return const [];
    return orders.fetchOrders();
  }

  @override
  Future<CustomerOrder> fetchOrder(String id) => orders.fetchOrderById(id);

  @override
  Future<CustomerOrder> claim(String id) async => _unsupported();

  @override
  Future<CustomerOrder> assign(String id, String? workerId) async =>
      _unsupported();

  @override
  Future<CustomerOrder> updateStatus(
    String id,
    OrderStatus status, {
    String? notes,
  }) async => _unsupported();

  @override
  Future<OrderDocumentation> uploadDocumentation({
    required String orderId,
    required DocumentationType type,
    required String imagePath,
    String? orderItemId,
  }) async => _unsupported();

  @override
  Future<void> deleteDocumentation({
    required String orderId,
    required String documentationId,
  }) async => _unsupported();

  @override
  Future<List<AssignableWorker>> fetchAssignableWorkers() async => const [];
}
