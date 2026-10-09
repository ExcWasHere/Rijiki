import 'package:rijiki/core/enums/event_type.dart';
import 'package:rijiki/core/mock/mock_scenario.dart';
import 'package:rijiki/features/event/domain/event_repository.dart';
import 'package:rijiki/features/event/domain/promo_event.dart';

class MockEventRepository implements EventRepository {
  const MockEventRepository({this.scenario = MockScenario.data});

  final MockScenario scenario;

  @override
  Future<List<PromoEvent>> fetchActiveEvents() {
    final now = DateTime.now();
    return scenario.resolve<List<PromoEvent>>(
      empty: const [],
      data: [
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
        PromoEvent(
          id: 'evt-3',
          title: 'Antar-jemput area Kota Malang',
          type: EventType.announcement,
          description: 'Cukup pilih alamat, kurir kami yang datang.',
        ),
      ],
    );
  }
}
