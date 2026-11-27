import 'package:rijiki/features/points/domain/point_ledger_entry.dart';
import 'package:rijiki/features/points/domain/point_redemption.dart';
import 'package:rijiki/features/points/domain/reward.dart';

/// Sisi customer: saldo, riwayat, hadiah, dan pengajuan tukar poin.
abstract interface class CustomerPointsRepository {
  Future<PointBalance> fetchBalance();

  Future<PointLedgerPage> fetchLedger({required int page, required int limit});

  /// Hadiah aktif yang punya harga poin.
  Future<List<Reward>> fetchRewards();

  /// Pengajuan tukar poin milik customer yang login (terbaru dulu).
  Future<List<PointRedemption>> fetchRedemptions({
    RedemptionStatus? status,
    int limit = 50,
  });

  /// Mengajukan penukaran; status awal `pending`. Poin baru dipotong saat
  /// owner menyetujui.
  Future<PointRedemption> requestRedemption(String merchandiseId);
}
