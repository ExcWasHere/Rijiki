import 'package:rijiki/core/enums/discount_type.dart';
import 'package:rijiki/core/mock/mock_scenario.dart';
import 'package:rijiki/features/event/domain/promo.dart';
import 'package:rijiki/features/event/domain/promo_input.dart';
import 'package:rijiki/features/event/domain/promo_repository.dart';

class MockPromoRepository implements PromoRepository {
  MockPromoRepository({this.scenario = MockScenario.data});

  final MockScenario scenario;

  static const Duration _writeLatency = Duration(milliseconds: 450);

  late final List<Promo> _promos = _seed();

  @override
  Future<List<Promo>> fetchAllPromos() {
    return scenario.resolve<List<Promo>>(
      empty: const [],
      data: List.of(_promos),
    );
  }

  @override
  Future<Promo> createPromo(PromoInput input) async {
    await _write();
    _ensureCodeFree(input.code);
    final promo = _fromInput(
      'promo-${DateTime.now().microsecondsSinceEpoch}',
      input,
    );
    _promos.add(promo);
    return promo;
  }

  @override
  Future<Promo> updatePromo(String id, PromoInput input) async {
    await _write();
    final index = _indexOf(id);
    _ensureCodeFree(input.code, exceptId: id);
    final updated = _fromInput(id, input);
    _promos[index] = updated;
    return updated;
  }

  @override
  Future<Promo> setPromoActive(String id, bool isActive) async {
    await _write();
    final index = _indexOf(id);
    final updated = _promos[index].copyWith(isActive: isActive);
    _promos[index] = updated;
    return updated;
  }

  Future<void> _write() async {
    await Future<void>.delayed(_writeLatency);
    if (scenario == MockScenario.error) throw const MockException();
  }

  int _indexOf(String id) {
    final index = _promos.indexWhere((p) => p.id == id);
    if (index == -1) throw const MockException('Promo tidak ditemukan');
    return index;
  }

  void _ensureCodeFree(String code, {String? exceptId}) {
    final taken = _promos.any(
      (p) => p.id != exceptId && p.code.toLowerCase() == code.toLowerCase(),
    );
    if (taken) throw const MockException('Kode promo sudah dipakai');
  }

  static Promo _fromInput(String id, PromoInput input) {
    final description = input.description?.trim() ?? '';
    return Promo(
      id: id,
      code: input.code.trim().toUpperCase(),
      title: input.title.trim(),
      discountType: input.discountType,
      discountValue: input.discountValue,
      startDate: input.startDate,
      endDate: input.endDate,
      description: description.isEmpty ? null : description,
      isActive: input.isActive,
    );
  }

  static List<Promo> _seed() {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    DateTime shift(int days) => today.add(Duration(days: days));

    return [
      Promo(
        id: 'promo-1',
        code: 'RIJIKI20',
        title: 'Diskon 20% Deep Clean',
        discountType: DiscountType.percentage,
        discountValue: 20,
        startDate: shift(-3),
        endDate: shift(14),
        description: 'Khusus order pertama kamu bulan ini.',
      ),
      Promo(
        id: 'promo-2',
        code: 'ONGKIR10',
        title: 'Potongan Antar-Jemput',
        discountType: DiscountType.fixed,
        discountValue: 10000,
        startDate: shift(5),
        endDate: shift(30),
      ),
      Promo(
        id: 'promo-3',
        code: 'MERDEKA17',
        title: 'Promo Kemerdekaan',
        discountType: DiscountType.percentage,
        discountValue: 17,
        startDate: shift(-70),
        endDate: shift(-45),
      ),
      Promo(
        id: 'promo-4',
        code: 'SEPATUBARU',
        title: 'Cuci Sepatu Baru',
        discountType: DiscountType.fixed,
        discountValue: 15000,
        startDate: shift(-10),
        endDate: shift(20),
        isActive: false,
      ),
    ];
  }
}
