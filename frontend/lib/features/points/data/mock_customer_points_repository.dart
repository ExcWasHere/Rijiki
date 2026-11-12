import 'package:rijiki/core/mock/mock_scenario.dart';
import 'package:rijiki/features/points/domain/customer_points_repository.dart';
import 'package:rijiki/features/points/domain/point_ledger_entry.dart';
import 'package:rijiki/features/points/domain/point_redemption.dart';
import 'package:rijiki/features/points/domain/reward.dart';

class MockCustomerPointsRepository implements CustomerPointsRepository {
  MockCustomerPointsRepository({this.scenario = MockScenario.data});

  final MockScenario scenario;

  static const Duration _writeLatency = Duration(milliseconds: 450);

  late final List<PointLedgerEntry> _entries = _seed();
  final List<PointRedemption> _redemptions = [];

  static const List<Reward> _rewards = [
    Reward(
      id: 'mrc-keychain',
      name: 'Keychain Sneaker',
      description: 'Gantungan kunci berbentuk sneaker.',
      pointsCost: 150,
      inStock: true,
    ),
    Reward(
      id: 'mrc-stiker',
      name: 'Stiker Set',
      description: 'Satu set isi 3 stiker.',
      pointsCost: 100,
      inStock: true,
    ),
    Reward(
      id: 'mrc-tote',
      name: 'Tote Bag',
      description: 'Tote bag gaya Rijiki.',
      pointsCost: 250,
      inStock: true,
    ),
    Reward(
      id: 'mrc-topi',
      name: 'Topi Rijiki',
      description: 'Stok sedang kosong.',
      pointsCost: 500,
      inStock: false,
    ),
  ];

  int get _balance => _entries.fold<int>(0, (sum, e) => sum + e.pointsAmount);

  @override
  Future<PointBalance> fetchBalance() {
    return scenario.resolve<PointBalance>(
      empty: const PointBalance(balance: 0),
      data: PointBalance(balance: _balance, recent: _entries.take(5).toList()),
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

  @override
  Future<List<Reward>> fetchRewards() {
    return scenario.resolve<List<Reward>>(empty: const [], data: _rewards);
  }

  @override
  Future<List<PointRedemption>> fetchRedemptions({
    RedemptionStatus? status,
    int limit = 50,
  }) {
    return scenario.resolve<List<PointRedemption>>(
      empty: const [],
      data: [
        for (final r in _redemptions)
          if (status == null || r.status == status) r,
      ].take(limit).toList(),
    );
  }

  @override
  Future<PointRedemption> requestRedemption(String merchandiseId) async {
    await Future<void>.delayed(_writeLatency);
    if (scenario == MockScenario.error) throw const MockException();

    final reward = _rewards.where((r) => r.id == merchandiseId).firstOrNull;
    if (reward == null) {
      throw const MockException('Merchandise sudah tidak tersedia.');
    }
    if (!reward.inStock) throw const MockException('Stok merchandise habis.');

    final reserved = _redemptions
        .where((r) => r.status == RedemptionStatus.pending)
        .fold<int>(0, (sum, r) => sum + r.pointsUsed);
    if (_balance - reserved < reward.pointsCost) {
      throw const MockException('Saldo poin tidak cukup.');
    }

    final redemption = PointRedemption(
      id: 'red-${DateTime.now().microsecondsSinceEpoch}',
      customerId: 'mock-customer',
      rewardName: reward.name,
      pointsUsed: reward.pointsCost,
      status: RedemptionStatus.pending,
      requestedAt: DateTime.now(),
      customerBalance: _balance,
    );
    _redemptions.insert(0, redemption);
    return redemption;
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
