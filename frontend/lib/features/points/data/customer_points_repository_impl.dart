import 'package:rijiki/core/error/app_exception.dart';
import 'package:rijiki/core/error/failure_mapper.dart';
import 'package:rijiki/core/network/api_client.dart';
import 'package:rijiki/core/network/api_endpoint.dart';
import 'package:rijiki/features/points/domain/customer_points_repository.dart';
import 'package:rijiki/features/points/domain/point_ledger_entry.dart';

class CustomerPointsRepositoryImpl implements CustomerPointsRepository {
  CustomerPointsRepositoryImpl({required this.api});

  final ApiClient api;

  @override
  Future<PointBalance> fetchBalance() async {
    try {
      final json = await api.get(ApiEndpoints.pointBalance, auth: true);
      return PointBalance.fromJson(json);
    } on AppException catch (e) {
      throw failureFromException(e);
    }
  }

  @override
  Future<PointLedgerPage> fetchLedger({
    required int page,
    required int limit,
  }) async {
    try {
      final json = await api.get(
        Uri(
          path: ApiEndpoints.pointLedger,
          queryParameters: {'page': '$page', 'limit': '$limit'},
        ).toString(),
        auth: true,
      );
      final raw = json['items'] as List<dynamic>? ?? const [];
      return PointLedgerPage(
        items: [
          for (final item in raw)
            PointLedgerEntry.fromJson(item as Map<String, dynamic>),
        ],
        total: (json['total'] as num? ?? 0).round(),
      );
    } on AppException catch (e) {
      throw failureFromException(e);
    }
  }
}
