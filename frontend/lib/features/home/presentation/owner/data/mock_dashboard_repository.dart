import 'package:rijiki/core/enums/order_status.dart';
import 'package:rijiki/features/home/presentation/owner/domain/dashboard_repository.dart';
import 'package:rijiki/features/home/presentation/owner/domain/dashboard_summary.dart';
import 'package:rijiki/features/home/presentation/owner/domain/recent_order.dart';
import 'package:rijiki/features/home/presentation/owner/domain/repeat_customer.dart';

class MockDashboardRepository implements DashboardRepository {
  static const int _activeOrders = 8;
  static const Duration _latency = Duration(milliseconds: 350);

  @override
  Future<DashboardSummary> fetchSummary(DashboardPeriod period) async {
    await Future<void>.delayed(_latency);

    switch (period) {
      case DashboardPeriod.today:
        return _build(
          period: period,
          labels: const ['08', '10', '12', '14', '16', '18', '20'],
          amounts: const [
            85000,
            140000,
            210000,
            95000,
            260000,
            180000,
            120000,
          ],
          expense: 320000,
          previousIncome: 940000,
        );
      case DashboardPeriod.week:
        return _build(
          period: period,
          labels: const ['Sen', 'Sel', 'Rab', 'Kam', 'Jum', 'Sab', 'Min'],
          amounts: const [
            1200000,
            950000,
            1450000,
            1100000,
            1800000,
            2350000,
            1650000,
          ],
          expense: 3400000,
          previousIncome: 9200000,
        );
      case DashboardPeriod.month:
        return _build(
          period: period,
          labels: const ['Mg 1', 'Mg 2', 'Mg 3', 'Mg 4'],
          amounts: const [8400000, 9100000, 10600000, 11200000],
          expense: 14200000,
          previousIncome: 36500000,
        );
    }
  }

  @override
  Future<List<RecentOrder>> fetchRecentOrders({int limit = 5}) async {
    await Future<void>.delayed(_latency);

    final now = DateTime.now();
    final orders = [
      RecentOrder(
        id: 'order-005',
        orderNumber: 'RJK-1010-005',
        customerName: 'Dewi Lestari',
        itemCount: 2,
        total: 120000,
        status: OrderStatus.cleaning,
        createdAt: now.subtract(const Duration(minutes: 25)),
      ),
      RecentOrder(
        id: 'order-004',
        orderNumber: 'RJK-1010-004',
        customerName: 'Bagas Pratama',
        itemCount: 1,
        total: 75000,
        status: OrderStatus.pickup,
        createdAt: now.subtract(const Duration(hours: 1, minutes: 10)),
      ),
      RecentOrder(
        id: 'order-003',
        orderNumber: 'RJK-1010-003',
        customerName: 'Salsa Nuraini',
        itemCount: 3,
        total: 210000,
        status: OrderStatus.delivery,
        createdAt: now.subtract(const Duration(hours: 3)),
      ),
      RecentOrder(
        id: 'order-002',
        orderNumber: 'RJK-1010-002',
        customerName: 'Rizky Maulana',
        itemCount: 1,
        total: 65000,
        status: OrderStatus.order,
        createdAt: now.subtract(const Duration(hours: 4)),
      ),
      RecentOrder(
        id: 'order-001',
        orderNumber: 'RJK-0909-021',
        customerName: 'Anisa Putri',
        itemCount: 2,
        total: 140000,
        status: OrderStatus.completed,
        createdAt: now.subtract(const Duration(hours: 28)),
      ),
    ];
    return orders.take(limit).toList();
  }

  @override
  Future<List<RepeatCustomer>> fetchRepeatCustomers({int? limit}) async {
    await Future<void>.delayed(_latency);

    const customers = [
      RepeatCustomer(
        id: 'cust-01',
        name: 'Dewi Lestari',
        completedOrders: 9,
        totalSpent: 1260000,
      ),
      RepeatCustomer(
        id: 'cust-02',
        name: 'Rizky Maulana',
        completedOrders: 7,
        totalSpent: 880000,
      ),
      RepeatCustomer(
        id: 'cust-03',
        name: 'Anisa Putri',
        completedOrders: 6,
        totalSpent: 745000,
      ),
      RepeatCustomer(
        id: 'cust-04',
        name: 'Bagas Pratama',
        completedOrders: 5,
        totalSpent: 610000,
      ),
      RepeatCustomer(
        id: 'cust-05',
        name: 'Salsa Nuraini',
        completedOrders: 4,
        totalSpent: 540000,
      ),
      RepeatCustomer(
        id: 'cust-06',
        name: 'Fajar Nugroho',
        completedOrders: 3,
        totalSpent: 390000,
      ),
      RepeatCustomer(
        id: 'cust-07',
        name: 'Citra Maharani',
        completedOrders: 3,
        totalSpent: 365000,
      ),
      RepeatCustomer(
        id: 'cust-08',
        name: 'Yoga Saputra',
        completedOrders: 2,
        totalSpent: 210000,
      ),
    ];
    return limit == null ? customers : customers.take(limit).toList();
  }

  DashboardSummary _build({
    required DashboardPeriod period,
    required List<String> labels,
    required List<double> amounts,
    required double expense,
    required double previousIncome,
  }) {
    final series = [
      for (var i = 0; i < labels.length; i++)
        RevenuePoint(label: labels[i], amount: amounts[i]),
    ];
    return DashboardSummary(
      period: period,
      income: amounts.fold<double>(0, (sum, value) => sum + value),
      expense: expense,
      previousIncome: previousIncome,
      activeOrders: _activeOrders,
      series: series,
    );
  }
}
