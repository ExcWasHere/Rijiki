import 'package:rijiki/core/enums/order_status.dart';

enum OrderFilter {
  all,
  inProgress,
  completed,
  cancelled;

  bool matches(OrderStatus status) => switch (this) {
        OrderFilter.all => true,
        OrderFilter.inProgress => status.isActive,
        OrderFilter.completed => status == OrderStatus.completed,
        OrderFilter.cancelled => status == OrderStatus.cancelled,
      };
}
