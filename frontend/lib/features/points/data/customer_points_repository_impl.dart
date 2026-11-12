import 'package:rijiki/core/error/app_exception.dart';
import 'package:rijiki/core/error/failure_mapper.dart';
import 'package:rijiki/core/network/api_client.dart';
import 'package:rijiki/core/network/api_endpoint.dart';
import 'package:rijiki/features/points/domain/customer_points_repository.dart';
import 'package:rijiki/features/points/domain/point_ledger_entry.dart';
import 'package:rijiki/features/points/domain/point_redemption.dart';
import 'package:rijiki/features/points/domain/reward.dart';

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

  @override
  Future<List<Reward>> fetchRewards() async {
    try {
      final json = await api.get(ApiEndpoints.pointRewards, auth: true);
      final raw = json['items'] as List<dynamic>? ?? const [];
      return [
        for (final item in raw) Reward.fromJson(item as Map<String, dynamic>),
      ];
    } on AppException catch (e) {
      throw failureFromException(e);
    }
  }

  @override
  Future<List<PointRedemption>> fetchRedemptions({
    RedemptionStatus? status,
    int limit = 50,
  }) async {
    try {
      final json = await api.get(
        Uri(
          path: ApiEndpoints.pointRedemptions,
          queryParameters: {
            'page': '1',
            'limit': '$limit',
            if (status != null) 'status': status.value,
          },
        ).toString(),
        auth: true,
      );
      final raw = json['items'] as List<dynamic>? ?? const [];
      return [
        for (final item in raw)
          PointRedemption.fromJson(item as Map<String, dynamic>),
      ];
    } on AppException catch (e) {
      throw failureFromException(e);
    }
  }

  @override
  Future<PointRedemption> requestRedemption(String merchandiseId) async {
    try {
      final json = await api.post(
        ApiEndpoints.pointRedemptions,
        auth: true,
        body: {'merchandise_id': merchandiseId},
      );
      return PointRedemption.fromJson(json);
    } on AppException catch (e) {
      throw failureFromException(e);
    }
  }
}
