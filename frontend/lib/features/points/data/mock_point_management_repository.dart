import 'package:rijiki/core/error/failure.dart';
import 'package:rijiki/core/mock/mock_scenario.dart';
import 'package:rijiki/features/points/domain/point_management_repository.dart';
import 'package:rijiki/features/points/domain/point_redemption.dart';

class MockPointManagementRepository implements PointManagementRepository {
  MockPointManagementRepository({this.scenario = MockScenario.data});

  final MockScenario scenario;

  static const Duration _latency = Duration(milliseconds: 450);

  late final List<PointCustomer> _customers = [
    const PointCustomer(
      id: 'cust-01',
      name: 'Dewi Lestari',
      email: 'dewi@mail.com',
      phone: '+6281234567890',
      balance: 420,
    ),
    const PointCustomer(
      id: 'cust-02',
      name: 'Rizky Maulana',
      email: 'rizky@mail.com',
      phone: '+6285711112222',
      balance: 120,
    ),
    const PointCustomer(
      id: 'cust-03',
      name: 'Anisa Putri',
      email: 'anisa@mail.com',
      phone: '+6281399990000',
      balance: 260,
    ),
  ];

  late final List<PointRedemption> _redemptions = [
    PointRedemption(
      id: 'red-1',
      customerId: 'cust-01',
      customerName: 'Dewi Lestari',
      customerPhone: '+6281234567890',
      customerBalance: 420,
      rewardName: 'Tote Bag',
      pointsUsed: 250,
      status: RedemptionStatus.pending,
      requestedAt: DateTime.now().subtract(const Duration(hours: 3)),
    ),
    PointRedemption(
      id: 'red-2',
      customerId: 'cust-02',
      customerName: 'Rizky Maulana',
      customerPhone: '+6285711112222',
      customerBalance: 120,
      rewardName: 'Keychain Sneaker',
      pointsUsed: 150,
      status: RedemptionStatus.pending,
      requestedAt: DateTime.now().subtract(const Duration(days: 1)),
    ),
    PointRedemption(
      id: 'red-3',
      customerId: 'cust-03',
      customerName: 'Anisa Putri',
      customerBalance: 260,
      rewardName: 'Stiker Set',
      pointsUsed: 100,
      status: RedemptionStatus.approved,
      requestedAt: DateTime.now().subtract(const Duration(days: 2)),
      processedAt: DateTime.now().subtract(const Duration(days: 1)),
      processedByName: 'Owner',
    ),
  ];

  Future<void> _write() async {
    await Future<void>.delayed(_latency);
    if (scenario == MockScenario.error) throw const MockException();
  }

  int _pending() =>
      _redemptions.where((r) => r.status == RedemptionStatus.pending).length;

  @override
  Future<RedemptionList> fetchRedemptions({RedemptionStatus? status}) {
    final items = [
      for (final r in _redemptions)
        if (status == null || r.status == status) r,
    ];
    return scenario.resolve<RedemptionList>(
      empty: const RedemptionList(items: [], total: 0, pendingCount: 0),
      data: RedemptionList(
        items: items,
        total: items.length,
        pendingCount: _pending(),
      ),
    );
  }

  @override
  Future<int> fetchPendingCount() async {
    final result = await fetchRedemptions(status: RedemptionStatus.pending);
    return result.pendingCount;
  }

  @override
  Future<PointRedemption> processRedemption(
    String id, {
    required RedemptionStatus status,
    String? notes,
  }) async {
    await _write();
    final index = _redemptions.indexWhere((r) => r.id == id);
    if (index == -1) {
      throw Failure(FailureType.unknown, 'Pengajuan tidak ditemukan.');
    }
    final current = _redemptions[index];
    final allowed = status == RedemptionStatus.fulfilled
        ? current.status == RedemptionStatus.approved
        : current.status == RedemptionStatus.pending;
    if (!allowed) {
      throw Failure(
        FailureType.unknown,
        'Status pengajuan sudah berubah. Muat ulang lalu coba lagi.',
      );
    }

    var balance = current.customerBalance;
    if (status == RedemptionStatus.approved) {
      if (balance < current.pointsUsed) {
        throw Failure(FailureType.unknown, 'Saldo poin tidak cukup.');
      }
      balance -= current.pointsUsed;
      final c = _customers.indexWhere((x) => x.id == current.customerId);
      if (c != -1) _customers[c] = _customers[c].copyWith(balance: balance);
    }

    final trimmed = notes?.trim() ?? '';
    final updated = current.copyWith(
      status: status,
      notes: trimmed.isEmpty ? null : trimmed,
      processedAt: DateTime.now(),
      processedByName: 'Kamu',
      customerBalance: balance,
    );
    _redemptions[index] = updated;
    return updated;
  }

  @override
  Future<List<PointCustomer>> searchCustomers(String query) async {
    await Future<void>.delayed(const Duration(milliseconds: 250));
    if (scenario == MockScenario.error) throw const MockException();
    final q = query.trim().toLowerCase();
    return [
      for (final c in _customers)
        if (c.displayName.toLowerCase().contains(q) ||
            c.email.toLowerCase().contains(q) ||
            (c.phone ?? '').contains(q))
          c,
    ];
  }

  @override
  Future<int> adjustPoints({
    required String customerId,
    required int points,
    required String description,
  }) async {
    await _write();
    final index = _customers.indexWhere((c) => c.id == customerId);
    if (index == -1) {
      throw Failure(FailureType.unknown, 'Customer tidak ditemukan.');
    }
    final next = _customers[index].balance + points;
    if (next < 0) throw Failure(FailureType.unknown, 'Saldo poin tidak cukup.');
    _customers[index] = _customers[index].copyWith(balance: next);
    return next;
  }
}
