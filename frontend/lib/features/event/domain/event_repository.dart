import 'package:rijiki/features/event/domain/promo_event.dart';

abstract interface class EventRepository {
  Future<List<PromoEvent>> fetchActiveEvents();
}
