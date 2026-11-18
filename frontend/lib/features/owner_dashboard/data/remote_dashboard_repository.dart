import 'package:rijiki/core/enums/order_status.dart';
import 'package:rijiki/core/error/app_exception.dart';
import 'package:rijiki/core/error/failure_mapper.dart';
import 'package:rijiki/core/network/api_client.dart';
import 'package:rijiki/core/network/api_endpoint.dart';
import 'package:rijiki/features/owner_dashboard/domain/dashboard_repository.dart';
import 'package:rijiki/features/owner_dashboard/domain/dashboard_summary.dart';
import 'package:rijiki/features/owner_dashboard/domain/recent_order.dart';
import 'package:rijiki/features/owner_dashboard/domain/repeat_customer.dart';

/// Dashboard owner dari backend: ringkasan dan order terbaru lewat
/// `/api/management/analytics`, repeat customer lewat
/// `/api/management/customers/repeat`.
class RemoteDashboardRepository implements DashboardRepository {
  RemoteDashboardRepository({required this.api});

  final ApiClient api;

  static const int _pageSize = 50;
  static const int _maxPages = 10;

  @override
  Future<DashboardSummary> fetchSummary(DashboardPeriod period) async {
    try {
      final json = await api.get(
        Uri(
          path: ApiEndpoints.dashboardSummary,
          queryParameters: {'period': period.name},
        ).toString(),
        auth: true,
      );

      return DashboardSummary(
        period: period,
        income: _double(json['income']),
        expense: _double(json['expense']),
        previousIncome: _double(json['previous_income']),
        activeOrders: (json['active_orders'] as num? ?? 0).round(),
        series: [
          for (final point in json['series'] as List<dynamic>? ?? const [])
            RevenuePoint(
              label: (point as Map<String, dynamic>)['label'] as String? ?? '',
              amount: _double(point['amount']),
            ),
        ],
      );
    } on AppException catch (e) {
      throw failureFromException(e);
    }
  }

  @override
  Future<List<RecentOrder>> fetchRecentOrders({int limit = 5}) async {
    try {
      final json = await api.get(
        Uri(
          path: ApiEndpoints.dashboardRecentOrders,
          queryParameters: {'limit': '$limit'},
        ).toString(),
        auth: true,
      );

      return [
        for (final raw in json['items'] as List<dynamic>? ?? const [])
          _recentOrderFromJson(raw as Map<String, dynamic>),
      ];
    } on AppException catch (e) {
      throw failureFromException(e);
    }
  }

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

  static double _double(Object? value) => (value as num? ?? 0).toDouble();

  static RecentOrder _recentOrderFromJson(Map<String, dynamic> json) {
    return RecentOrder(
      id: json['id'] as String,
      orderNumber: json['order_number'] as String? ?? '-',
      customerName: json['customer_name'] as String? ?? 'Pelanggan',
      itemCount: (json['item_count'] as num? ?? 0).round(),
      total: (json['total'] as num? ?? 0).round(),
      status: OrderStatus.fromJson(json['status'] as String? ?? 'order'),
      createdAt: DateTime.tryParse(json['created_at'] as String? ?? '') ??
          DateTime.now(),
    );
  }
}
