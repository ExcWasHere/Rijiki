import 'package:rijiki/features/home/presentation/owner/domain/dashboard_summary.dart';
import 'package:rijiki/features/home/presentation/owner/domain/recent_order.dart';
import 'package:rijiki/features/home/presentation/owner/domain/repeat_customer.dart';

abstract interface class DashboardRepository {
  Future<DashboardSummary> fetchSummary(DashboardPeriod period);
  Future<List<RecentOrder>> fetchRecentOrders({int limit = 5});
  Future<List<RepeatCustomer>> fetchRepeatCustomers({int? limit});
}
