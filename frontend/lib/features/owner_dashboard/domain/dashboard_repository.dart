import 'package:rijiki/features/owner_dashboard/domain/dashboard_summary.dart';
import 'package:rijiki/features/owner_dashboard/domain/recent_order.dart';
import 'package:rijiki/features/owner_dashboard/domain/repeat_customer.dart';

abstract interface class DashboardRepository {
  Future<DashboardSummary> fetchSummary(DashboardPeriod period);
  Future<List<RecentOrder>> fetchRecentOrders({int limit = 5});
  Future<List<RepeatCustomer>> fetchRepeatCustomers({int? limit});
}
