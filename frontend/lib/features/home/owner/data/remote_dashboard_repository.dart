import 'package:rijiki/core/error/app_exception.dart';
import 'package:rijiki/core/error/failure_mapper.dart';
import 'package:rijiki/core/network/api_client.dart';
import 'package:rijiki/core/network/api_endpoint.dart';
import 'package:rijiki/features/home/owner/domain/dashboard_repository.dart';
import 'package:rijiki/features/home/owner/domain/dashboard_summary.dart';
import 'package:rijiki/features/home/owner/domain/recent_order.dart';
import 'package:rijiki/features/home/owner/domain/repeat_customer.dart';

/// Dashboard owner: bagian repeat customer sudah dari backend
/// (`/api/management/customers/repeat`). Ringkasan dan order terbaru masih
/// memakai [fallback] (mock) sampai endpoint analitiknya dibuat.
class RemoteDashboardRepository implements DashboardRepository {
  RemoteDashboardRepository({required this.api, required this.fallback});

  final ApiClient api;
  final DashboardRepository fallback;

  static const int _pageSize = 50;
  static const int _maxPages = 10;

  @override
  Future<DashboardSummary> fetchSummary(DashboardPeriod period) =>
      fallback.fetchSummary(period);

  @override
  Future<List<RecentOrder>> fetchRecentOrders({int limit = 5}) =>
      fallback.fetchRecentOrders(limit: limit);

  @override
  Future<List<RepeatCustomer>> fetchRepeatCustomers({int? limit}) async {
    try {
      if (limit != null) {
        final page = await _fetchPage(1, limit.clamp(1, _pageSize).toInt());
        return page.items;
      }

      final all = <RepeatCustomer>[];
      for (var page = 1; page <= _maxPages; page++) {
        final result = await _fetchPage(page, _pageSize);
        all.addAll(result.items);
        if (result.items.length < _pageSize || all.length >= result.total) {
          break;
        }
      }
      return all;
    } on AppException catch (e) {
      throw failureFromException(e);
    }
  }

  Future<({List<RepeatCustomer> items, int total})> _fetchPage(
    int page,
    int limit,
  ) async {
    final json = await api.get(
      Uri(
        path: ApiEndpoints.repeatCustomers,
        queryParameters: {'page': '$page', 'limit': '$limit'},
      ).toString(),
      auth: true,
    );
    final raw = json['items'] as List<dynamic>? ?? const [];
    return (
      items: [
        for (final item in raw)
          RepeatCustomer.fromJson(item as Map<String, dynamic>),
      ],
      total: (json['total'] as num? ?? 0).round(),
    );
  }
}
