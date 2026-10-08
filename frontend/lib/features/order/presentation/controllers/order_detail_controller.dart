import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:rijiki/app/providers.dart';
import 'package:rijiki/features/order/domain/customer_order.dart';

Duration? _noRetry(int retryCount, Object error) => null;

final orderDetailProvider = FutureProvider.family<CustomerOrder, String>((
  ref,
  orderId,
) {
  return ref.watch(orderRepositoryProvider).fetchOrderById(orderId);
}, retry: _noRetry);
