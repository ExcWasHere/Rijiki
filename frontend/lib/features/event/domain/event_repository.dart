import 'package:rijiki/features/event/domain/promo_event.dart';
import 'package:rijiki/features/event/domain/promo_event_input.dart';

abstract interface class EventRepository {
  Future<List<PromoEvent>> fetchActiveEvents();
  Future<List<PromoEvent>> fetchAllEvents();

  Future<PromoEvent> createEvent(PromoEventInput input);

  Future<PromoEvent> updateEvent(String id, PromoEventInput input);
  Future<PromoEvent> setEventPublished(String id, bool isPublished);
}
