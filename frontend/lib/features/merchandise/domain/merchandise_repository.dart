import 'package:rijiki/features/merchandise/domain/merchandise.dart';
import 'package:rijiki/features/merchandise/domain/merchandise_input.dart';

abstract interface class MerchandiseRepository {
  Future<List<Merchandise>> fetchActiveMerchandise();
  Future<List<Merchandise>> fetchAllMerchandise();

  Future<Merchandise> createMerchandise(MerchandiseInput input);

  Future<Merchandise> updateMerchandise(String id, MerchandiseInput input);
  Future<Merchandise> setMerchandiseActive(String id, bool isActive);
}
