import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:rijiki/app/providers.dart';
import 'package:rijiki/features/order/domain/customer_order.dart';
import 'package:rijiki/features/order/domain/order_filter.dart';

Duration? _noRetry(int retryCount, Object error) => null;

class OrderFilterController extends Notifier<OrderFilter> {
  @override
  OrderFilter build() => OrderFilter.all;

  void select(OrderFilter filter) => state = filter;
}

final orderFilterProvider =
    NotifierProvider<OrderFilterController, OrderFilter>(
      OrderFilterController.new,
    );

final ordersProvider = FutureProvider<List<CustomerOrder>>((ref) {
  return ref.watch(orderRepositoryProvider).fetchOrders();
}, retry: _noRetry);

final filteredOrdersProvider = Provider<AsyncValue<List<CustomerOrder>>>((ref) {
  final filter = ref.watch(orderFilterProvider);
  return ref
      .watch(ordersProvider)
      .whenData(
        (orders) =>
            orders.where((order) => filter.matches(order.status)).toList(),
      );
});

Future<void> refreshOrders(WidgetRef ref) async {
  try {
    await ref.refresh(ordersProvider.future);
  } catch (_) {
  }
}
