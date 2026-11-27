import 'package:rijiki/features/event/domain/promo.dart';
import 'package:rijiki/features/event/domain/promo_input.dart';

abstract interface class PromoRepository {
  Future<List<Promo>> fetchAllPromos();

  Future<Promo> createPromo(PromoInput input);

  Future<Promo> updatePromo(String id, PromoInput input);

  Future<Promo> setPromoActive(String id, bool isActive);
}
