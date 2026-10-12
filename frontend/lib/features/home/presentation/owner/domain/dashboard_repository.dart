import 'package:rijiki/features/home/presentation/owner/domain/dashboard_summary.dart';
import 'package:rijiki/features/home/presentation/owner/domain/recent_order.dart';
import 'package:rijiki/features/home/presentation/owner/domain/repeat_customer.dart';

abstract interface class DashboardRepository {
  Future<DashboardSummary> fetchSummary(DashboardPeriod period);

  /// Order terbaru, urut dari yang paling baru.
  Future<List<RecentOrder>> fetchRecentOrders({int limit = 5});

  /// Repeat customer, urut dari order selesai terbanyak.
  /// [limit] null berarti ambil semua.
  Future<List<RepeatCustomer>> fetchRepeatCustomers({int? limit});
}
