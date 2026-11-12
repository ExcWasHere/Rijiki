import 'package:rijiki/features/points/domain/point_ledger_entry.dart';

abstract interface class CustomerPointsRepository {
  Future<PointBalance> fetchBalance();

  Future<PointLedgerPage> fetchLedger({required int page, required int limit});
}
