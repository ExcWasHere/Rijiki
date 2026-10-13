import 'package:rijiki/features/home/owner/domain/dashboard_summary.dart';

abstract interface class DashboardRepository {
  Future<DashboardSummary> fetchSummary(DashboardPeriod period);
}