import 'package:rijiki/core/enums/event_type.dart';
import 'package:rijiki/core/mock/mock_scenario.dart';
import 'package:rijiki/features/event/domain/event_repository.dart';
import 'package:rijiki/features/event/domain/promo_event.dart';
import 'package:rijiki/features/event/domain/promo_event_input.dart';

class MockEventRepository implements EventRepository {
  MockEventRepository({this.scenario = MockScenario.data});

  final MockScenario scenario;

  static const Duration _writeLatency = Duration(milliseconds: 450);

  late final List<PromoEvent> _events = _seed();

  @override
  Future<List<PromoEvent>> fetchActiveEvents() {
    return scenario.resolve<List<PromoEvent>>(
      empty: const [],
      data: [
        for (final event in _events)
          if (event.isPublished) event,
      ],
    );
  }

  @override
  Future<List<PromoEvent>> fetchAllEvents() {
    return scenario.resolve<List<PromoEvent>>(
      empty: const [],
      data: List.of(_events),
    );
  }

  @override
  Future<PromoEvent> createEvent(PromoEventInput input) async {
    await _write();
    final event = _fromInput(
      'evt-${DateTime.now().microsecondsSinceEpoch}',
      input,
    );
    _events.add(event);
    return event;
  }

  @override
  Future<PromoEvent> updateEvent(String id, PromoEventInput input) async {
    await _write();
    final index = _indexOf(id);
    final updated = _fromInput(id, input);
    _events[index] = updated;
    return updated;
  }

  @override
  Future<PromoEvent> setEventPublished(String id, bool isPublished) async {
    await _write();
    final index = _indexOf(id);
    final updated = _events[index].copyWith(isPublished: isPublished);
    _events[index] = updated;
    return updated;
  }

  Future<void> _write() async {
    await Future<void>.delayed(_writeLatency);
    if (scenario == MockScenario.error) throw const MockException();
  }

  int _indexOf(String id) {
    final index = _events.indexWhere((e) => e.id == id);
    if (index == -1) throw const MockException('Event tidak ditemukan');
    return index;
  }

  static PromoEvent _fromInput(String id, PromoEventInput input) {
    final description = input.description?.trim() ?? '';
    final banner = input.bannerImageUrl?.trim() ?? '';
    return PromoEvent(
      id: id,
      title: input.title.trim(),
      type: input.type,
      description: description.isEmpty ? null : description,
      bannerImageUrl: banner.isEmpty ? null : banner,
      startDate: input.startDate,
      endDate: input.endDate,
      isPublished: input.isPublished,
    );
  }

  static List<PromoEvent> _seed() {
    final now = DateTime.now();
    return [
      PromoEvent(
        id: 'evt-1',
        title: 'Diskon 20% Deep Clean',
        type: EventType.promo,
        description: 'Khusus order pertama kamu bulan ini.',
        endDate: now.add(const Duration(days: 14)),
      ),
      PromoEvent(
        id: 'evt-2',
        title: 'Rijiki x Komunitas Sepatu Malang',
        type: EventType.collaboration,
        description: 'Cuci bareng dan ngobrol soal rawat sneakers.',
        startDate: now.add(const Duration(days: 6)),
      ),
      const PromoEvent(
        id: 'evt-3',
        title: 'Antar-jemput area Kota Malang',
        type: EventType.announcement,
        description: 'Cukup pilih alamat, kurir kami yang datang.',
      ),
    ];
  }
}
