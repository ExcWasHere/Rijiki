import 'package:rijiki/features/event/domain/promo_event.dart';
import 'package:rijiki/features/event/domain/promo_event_input.dart';
import 'package:rijiki/features/event/domain/promo_option.dart';

abstract interface class EventRepository {
  /// Customer: event yang sedang tayang.
  Future<List<PromoEvent>> fetchActiveEvents();

  /// Owner / worker berizin: semua event, termasuk yang disembunyikan.
  Future<List<PromoEvent>> fetchAllEvents();

  Future<PromoEvent> createEvent(PromoEventInput input);

  Future<PromoEvent> updateEvent(String id, PromoEventInput input);
  Future<PromoEvent> setEventPublished(String id, bool isPublished);

  /// Pilihan promo untuk dropdown di form event.
  Future<List<PromoOption>> fetchPromoOptions();
}
