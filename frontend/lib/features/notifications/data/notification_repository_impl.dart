import 'package:rijiki/core/error/app_exception.dart';
import 'package:rijiki/core/error/failure_mapper.dart';
import 'package:rijiki/core/network/api_client.dart';
import 'package:rijiki/core/network/api_endpoint.dart';
import 'package:rijiki/features/notifications/domain/app_notification.dart';
import 'package:rijiki/features/notifications/domain/notification_repository.dart';

class NotificationRepositoryImpl implements NotificationRepository {
  NotificationRepositoryImpl({required this.api});

  final ApiClient api;

  @override
  Future<NotificationPage> fetch({
    required int page,
    required int limit,
  }) async {
    try {
      final json = await api.get(
        Uri(
          path: ApiEndpoints.notifications,
          queryParameters: {'page': '$page', 'limit': '$limit'},
        ).toString(),
        auth: true,
      );
      final raw = json['items'] as List<dynamic>? ?? const [];
      return NotificationPage(
        items: [
          for (final item in raw)
            AppNotification.fromJson(item as Map<String, dynamic>),
        ],
        total: (json['total'] as num? ?? 0).round(),
        unread: (json['unread'] as num? ?? 0).round(),
      );
    } on AppException catch (e) {
      throw failureFromException(e);
    }
  }

  @override
  Future<int> fetchUnreadCount() async {
    try {
      final json = await api.get(
        ApiEndpoints.notificationUnreadCount,
        auth: true,
      );
      return (json['unread'] as num? ?? 0).round();
    } on AppException catch (e) {
      throw failureFromException(e);
    }
  }

  @override
  Future<int> markRead(String id) async {
    try {
      final json = await api.post(
        ApiEndpoints.notificationRead(id),
        auth: true,
      );
      return (json['unread'] as num? ?? 0).round();
    } on AppException catch (e) {
      throw failureFromException(e);
    }
  }

  @override
  Future<void> markAllRead() async {
    try {
      await api.post(ApiEndpoints.notificationReadAll, auth: true);
    } on AppException catch (e) {
      throw failureFromException(e);
    }
  }

  @override
  Future<void> registerDevice({
    required String token,
    required String platform,
  }) async {
    try {
      await api.post(
        ApiEndpoints.devices,
        auth: true,
        body: {'token': token, 'platform': platform},
      );
    } on AppException catch (e) {
      throw failureFromException(e);
    }
  }

  @override
  Future<void> unregisterDevice(String token) async {
    try {
      await api.delete(
        ApiEndpoints.devices,
        auth: true,
        body: {'token': token},
      );
    } on AppException catch (e) {
      throw failureFromException(e);
    }
  }
}
