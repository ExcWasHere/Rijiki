import 'package:rijiki/features/points/domain/point_redemption.dart';

/// Penukaran dan penyesuaian poin untuk owner / worker berizin `manage_points`.
abstract interface class PointManagementRepository {
  Future<RedemptionList> fetchRedemptions({RedemptionStatus? status});

  /// Jumlah pengajuan yang menunggu (untuk lencana di hub poin).
  Future<int> fetchPendingCount();

  Future<PointRedemption> processRedemption(
    String id, {
    required RedemptionStatus status,
    String? notes,
  });

  Future<List<PointCustomer>> searchCustomers(String query);

  /// Mengembalikan saldo baru. [points] negatif untuk mengurangi.
  Future<int> adjustPoints({
    required String customerId,
    required int points,
    required String description,
  });
}
