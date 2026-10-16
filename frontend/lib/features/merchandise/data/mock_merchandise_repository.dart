import 'package:rijiki/core/mock/mock_scenario.dart';
import 'package:rijiki/features/merchandise/domain/merchandise.dart';
import 'package:rijiki/features/merchandise/domain/merchandise_input.dart';
import 'package:rijiki/features/merchandise/domain/merchandise_repository.dart';

class MockMerchandiseRepository implements MerchandiseRepository {
  MockMerchandiseRepository({this.scenario = MockScenario.data});

  final MockScenario scenario;

  static const Duration _writeLatency = Duration(milliseconds: 450);

  static const List<Merchandise> _seed = [
    Merchandise(
      id: 'mrc-keychain',
      name: 'Keychain Sneaker',
      price: 15000,
      pointsCost: 150,
      stockQuantity: 25,
      description: 'Gantungan kunci berbentuk sneaker.',
    ),
    Merchandise(
      id: 'mrc-stiker',
      name: 'Stiker Set',
      price: 10000,
      pointsCost: 100,
      stockQuantity: 40,
      description: 'Satu set isi 3 stiker.',
    ),
    Merchandise(
      id: 'mrc-tote',
      name: 'Tote Bag',
      price: 45000,
      pointsCost: 250,
      stockQuantity: 12,
      description: 'Tote bag gaya Rijiki.',
    ),
    Merchandise(
      id: 'mrc-sikat',
      name: 'Sikat Sepatu Premium',
      price: 35000,
      description: 'Belum bisa ditukar poin.',
    ),
  ];

  late final List<Merchandise> _items = List.of(_seed);

  @override
  Future<List<Merchandise>> fetchActiveMerchandise() {
    return scenario.resolve<List<Merchandise>>(
      empty: const [],
      data: [
        for (final item in _items)
          if (item.isActive) item,
      ],
    );
  }

  @override
  Future<List<Merchandise>> fetchAllMerchandise() {
    return scenario.resolve<List<Merchandise>>(
      empty: const [],
      data: List.of(_items),
    );
  }

  @override
  Future<Merchandise> createMerchandise(MerchandiseInput input) async {
    await _write();
    final item = _fromInput('mrc-${DateTime.now().microsecondsSinceEpoch}', input);
    _items.add(item);
    return item;
  }

  @override
  Future<Merchandise> updateMerchandise(String id, MerchandiseInput input) async {
    await _write();
    final index = _indexOf(id);
    final updated = _fromInput(id, input);
    _items[index] = updated;
    return updated;
  }

  @override
  Future<Merchandise> setMerchandiseActive(String id, bool isActive) async {
    await _write();
    final index = _indexOf(id);
    final updated = _items[index].copyWith(isActive: isActive);
    _items[index] = updated;
    return updated;
  }

  Future<void> _write() async {
    await Future<void>.delayed(_writeLatency);
    if (scenario == MockScenario.error) throw const MockException();
  }

  int _indexOf(String id) {
    final index = _items.indexWhere((m) => m.id == id);
    if (index == -1) throw const MockException('Merchandise tidak ditemukan');
    return index;
  }

  static Merchandise _fromInput(String id, MerchandiseInput input) {
    final description = input.description?.trim() ?? '';
    final image = input.imageUrl?.trim() ?? '';
    return Merchandise(
      id: id,
      name: input.name.trim(),
      price: input.price,
      pointsCost: input.pointsCost,
      stockQuantity: input.stockQuantity,
      description: description.isEmpty ? null : description,
      imageUrl: image.isEmpty ? null : image,
      isActive: input.isActive,
    );
  }
}
