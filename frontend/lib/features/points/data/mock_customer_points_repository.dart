import 'package:rijiki/core/mock/mock_scenario.dart';
import 'package:rijiki/features/points/domain/customer_points_repository.dart';
import 'package:rijiki/features/points/domain/point_ledger_entry.dart';

class MockCustomerPointsRepository implements CustomerPointsRepository {
  MockCustomerPointsRepository({this.scenario = MockScenario.data});

  final MockScenario scenario;

  late final List<PointLedgerEntry> _entries = _seed();

  @override
  Future<PointBalance> fetchBalance() {
    return scenario.resolve<PointBalance>(
      empty: const PointBalance(balance: 0),
      data: PointBalance(
        balance: _entries.fold<int>(0, (sum, e) => sum + e.pointsAmount),
        recent: _entries.take(5).toList(),
      ),
    );
  }

  @override
  Future<PointLedgerPage> fetchLedger({required int page, required int limit}) {
    return scenario.resolve<PointLedgerPage>(
      empty: const PointLedgerPage(items: [], total: 0),
      data: PointLedgerPage(
        items: _entries.skip((page - 1) * limit).take(limit).toList(),
        total: _entries.length,
      ),
    );
  }

  static List<PointLedgerEntry> _seed() {
    final now = DateTime.now();
    PointLedgerEntry entry(
      int daysAgo,
      PointLedgerType type,
      int points,
      String? description, {
      String? order,
    }) {
      return PointLedgerEntry(
        id: 'pl-$daysAgo-${type.value}',
        type: type,
        pointsAmount: points,
        description: description,
        orderNumber: order,
        createdAt: now.subtract(Duration(days: daysAgo)),
      );
    }

    return [
      entry(1, PointLedgerType.earn, 50, 'Order selesai', order: 'RJK-1105-003'),
      entry(1, PointLedgerType.earn, 20, 'Ulasan order', order: 'RJK-1105-003'),
      entry(4, PointLedgerType.redeem, -150, 'Tukar poin: Keychain'),
      entry(9, PointLedgerType.earn, 80, 'Order selesai', order: 'RJK-1030-011'),
      entry(14, PointLedgerType.adjustment, 100, 'Bonus komunitas sepatu'),
      entry(20, PointLedgerType.earn, 70, 'Order selesai', order: 'RJK-1019-004'),
      entry(30, PointLedgerType.earn, 150, 'Order selesai', order: 'RJK-1009-002'),
    ];
  }
}
