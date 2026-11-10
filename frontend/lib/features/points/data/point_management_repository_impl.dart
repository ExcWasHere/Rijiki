import 'package:rijiki/core/error/app_exception.dart';
import 'package:rijiki/core/error/failure_mapper.dart';
import 'package:rijiki/core/network/api_client.dart';
import 'package:rijiki/core/network/api_endpoint.dart';
import 'package:rijiki/features/points/domain/point_management_repository.dart';
import 'package:rijiki/features/points/domain/point_redemption.dart';

class PointManagementRepositoryImpl implements PointManagementRepository {
  PointManagementRepositoryImpl({required this.api});

  final ApiClient api;

  static const int _pageLimit = 50;

  @override
  Future<RedemptionList> fetchRedemptions({RedemptionStatus? status}) {
    return _list(status: status, limit: _pageLimit);
  }

  @override
  Future<int> fetchPendingCount() async {
    final result = await _list(status: RedemptionStatus.pending, limit: 1);
    return result.pendingCount;
  }

  Future<RedemptionList> _list({
    RedemptionStatus? status,
    required int limit,
  }) async {
    try {
      final json = await api.get(
        Uri(
          path: ApiEndpoints.managementPointRedemptions,
          queryParameters: {
            'page': '1',
            'limit': '$limit',
            if (status != null) 'status': status.value,
          },
        ).toString(),
        auth: true,
      );
      final raw = json['items'] as List<dynamic>? ?? const [];
      final summary = json['summary'] as Map<String, dynamic>?;
      return RedemptionList(
        items: [
          for (final item in raw)
            PointRedemption.fromJson(item as Map<String, dynamic>),
        ],
        total: (json['total'] as num? ?? 0).round(),
        pendingCount: (summary?['pending'] as num? ?? 0).round(),
      );
    } on AppException catch (e) {
      throw failureFromException(e);
    }
  }

  @override
  Future<PointRedemption> processRedemption(
    String id, {
    required RedemptionStatus status,
    String? notes,
  }) async {
    try {
      final trimmed = notes?.trim() ?? '';
      final json = await api.patch(
        ApiEndpoints.managementPointRedemption(id),
        auth: true,
        body: {
          'status': status.value,
          if (trimmed.isNotEmpty) 'notes': trimmed,
        },
      );
      return PointRedemption.fromJson(json);
    } on AppException catch (e) {
      throw failureFromException(e);
    }
  }

  @override
  Future<List<PointCustomer>> searchCustomers(String query) async {
    try {
      final json = await api.get(
        Uri(
          path: ApiEndpoints.managementPointCustomers,
          queryParameters: {'q': query.trim()},
        ).toString(),
        auth: true,
      );
      final raw = json['items'] as List<dynamic>? ?? const [];
      return [
        for (final item in raw)
          PointCustomer.fromJson(item as Map<String, dynamic>),
      ];
    } on AppException catch (e) {
      throw failureFromException(e);
    }
  }

  @override
  Future<int> adjustPoints({
    required String customerId,
    required int points,
    required String description,
  }) async {
    try {
      final json = await api.post(
        ApiEndpoints.managementPointAdjust,
        auth: true,
        body: {
          'customer_id': customerId,
          'points_amount': points,
          'description': description.trim(),
        },
      );
      return (json['points_balance'] as num? ?? 0).round();
    } on AppException catch (e) {
      throw failureFromException(e);
    }
  }
}
