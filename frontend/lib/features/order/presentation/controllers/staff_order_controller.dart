import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:rijiki/app/providers.dart';
import 'package:rijiki/core/enums/order_status.dart';
import 'package:rijiki/features/order/domain/assignable_worker.dart';
import 'package:rijiki/features/order/domain/customer_order.dart';
import 'package:rijiki/features/order/domain/order_documentation.dart';
import 'package:rijiki/features/order/domain/staff_order_repository.dart';

Duration? _noRetry(int retryCount, Object error) => null;
final staffOrdersProvider = FutureProvider.autoDispose
    .family<List<CustomerOrder>, StaffOrderList>((ref, list) {
      return ref.watch(staffOrderRepositoryProvider).fetchOrders(list);
    }, retry: _noRetry);

final staffOrderDetailProvider = FutureProvider.autoDispose
    .family<CustomerOrder, String>((ref, orderId) {
      return ref.watch(staffOrderRepositoryProvider).fetchOrder(orderId);
    }, retry: _noRetry);

final assignableWorkersProvider =
    FutureProvider.autoDispose<List<AssignableWorker>>((ref) {
      return ref.watch(staffOrderRepositoryProvider).fetchAssignableWorkers();
    }, retry: _noRetry);

class StaffOrderCommands {
  StaffOrderCommands(this._ref);

  final Ref _ref;

  StaffOrderRepository get _repo => _ref.read(staffOrderRepositoryProvider);

  void _refresh(String orderId) {
    _ref.invalidate(staffOrderDetailProvider(orderId));
    _ref.invalidate(staffOrdersProvider);
  }

  Future<CustomerOrder> claim(String orderId) async {
    final order = await _repo.claim(orderId);
    _refresh(orderId);
    return order;
  }

  Future<CustomerOrder> assign(String orderId, String? workerId) async {
    final order = await _repo.assign(orderId, workerId);
    _refresh(orderId);
    return order;
  }

  Future<CustomerOrder> updateStatus(
    String orderId,
    OrderStatus status, {
    String? notes,
  }) async {
    final order = await _repo.updateStatus(orderId, status, notes: notes);
    _refresh(orderId);
    return order;
  }

  Future<void> uploadDocumentation({
    required String orderId,
    required DocumentationType type,
    required String imagePath,
    String? orderItemId,
  }) async {
    await _repo.uploadDocumentation(
      orderId: orderId,
      type: type,
      imagePath: imagePath,
      orderItemId: orderItemId,
    );
    _refresh(orderId);
  }

  Future<void> deleteDocumentation({
    required String orderId,
    required String documentationId,
  }) async {
    await _repo.deleteDocumentation(
      orderId: orderId,
      documentationId: documentationId,
    );
    _refresh(orderId);
  }
}

final staffOrderCommandsProvider = Provider<StaffOrderCommands>(
  StaffOrderCommands.new,
);
