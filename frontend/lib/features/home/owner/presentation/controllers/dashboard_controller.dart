import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:rijiki/app/providers.dart';
import 'package:rijiki/features/home/owner/domain/dashboard_summary.dart';
import 'package:rijiki/features/home/owner/domain/recent_order.dart';
import 'package:rijiki/features/home/owner/domain/repeat_customer.dart';

class DashboardPeriodNotifier extends Notifier<DashboardPeriod> {
  @override
  DashboardPeriod build() => DashboardPeriod.today;

  void select(DashboardPeriod period) => state = period;
}

final dashboardPeriodProvider =
    NotifierProvider<DashboardPeriodNotifier, DashboardPeriod>(
      DashboardPeriodNotifier.new,
    );

final dashboardSummaryProvider = FutureProvider.autoDispose<DashboardSummary>((
  ref,
) {
  final period = ref.watch(dashboardPeriodProvider);
  return ref.watch(dashboardRepositoryProvider).fetchSummary(period);
});

final dashboardRecentOrdersProvider =
    FutureProvider.autoDispose<List<RecentOrder>>((ref) {
      return ref.watch(dashboardRepositoryProvider).fetchRecentOrders(limit: 5);
    });

final dashboardRepeatCustomersProvider =
    FutureProvider.autoDispose<List<RepeatCustomer>>((ref) {
      return ref
          .watch(dashboardRepositoryProvider)
          .fetchRepeatCustomers(limit: 3);
    });
final allRepeatCustomersProvider =
    FutureProvider.autoDispose<List<RepeatCustomer>>((ref) {
      return ref.watch(dashboardRepositoryProvider).fetchRepeatCustomers();
    });

Future<void> refreshDashboard(WidgetRef ref) async {
  ref.invalidate(dashboardSummaryProvider);
  ref.invalidate(dashboardRecentOrdersProvider);
  ref.invalidate(dashboardRepeatCustomersProvider);
  await Future.wait<Object?>([
    ref.read(dashboardSummaryProvider.future),
    ref.read(dashboardRecentOrdersProvider.future),
    ref.read(dashboardRepeatCustomersProvider.future),
  ]);
}
