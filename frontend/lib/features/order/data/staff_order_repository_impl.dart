import 'package:rijiki/core/constants/app_strings.dart';
import 'package:rijiki/core/enums/order_status.dart';
import 'package:rijiki/core/error/app_exception.dart';
import 'package:rijiki/core/error/failure.dart';
import 'package:rijiki/core/network/api_client.dart';
import 'package:rijiki/core/network/api_endpoint.dart';
import 'package:rijiki/features/order/data/order_mapper.dart';
import 'package:rijiki/features/order/domain/assignable_worker.dart';
import 'package:rijiki/features/order/domain/customer_order.dart';
import 'package:rijiki/features/order/domain/order_documentation.dart';
import 'package:rijiki/features/order/domain/staff_order_repository.dart';

class StaffOrderRepositoryImpl implements StaffOrderRepository {
  StaffOrderRepositoryImpl({required this.api});

  final ApiClient api;

  static const int _listLimit = 50;

  @override
  Future<List<CustomerOrder>> fetchOrders(StaffOrderList list) {
    return _guard(() async {
      final path = Uri(
        path: ApiEndpoints.orders,
        queryParameters: {
          'page': '1',
          'limit': '$_listLimit',
          if (list == StaffOrderList.unassigned) 'unassigned': 'true',
        },
      ).toString();
      final json = await api.get(path, auth: true);
      final raw = json['items'] as List<dynamic>? ?? const [];
      return [for (final item in raw) customerOrderFromJson(item as Json)];
    });
  }

  @override
  Future<CustomerOrder> fetchOrder(String id) {
    return _guard(() async {
      final json = await api.get(ApiEndpoints.orderById(id), auth: true);
      return customerOrderFromJson(json);
    });
  }

  @override
  Future<CustomerOrder> claim(String id) {
    return _guard(() async {
      final json = await api.post(ApiEndpoints.orderClaim(id), auth: true);
      return customerOrderFromJson(json);
    });
  }

  @override
  Future<CustomerOrder> assign(String id, String? workerId) {
    return _guard(() async {
      final json = await api.patch(
        ApiEndpoints.orderAssign(id),
        auth: true,
        body: {'worker_id': workerId},
      );
      return customerOrderFromJson(json);
    });
  }

  @override
  Future<CustomerOrder> updateStatus(
    String id,
    OrderStatus status, {
    String? notes,
  }) {
    return _guard(() async {
      final cleaned = notes?.trim() ?? '';
      final json = await api.patch(
        ApiEndpoints.orderStatus(id),
        auth: true,
        body: {
          'new_status': status.toJson(),
          if (cleaned.isNotEmpty) 'notes': cleaned,
        },
      );
      return customerOrderFromJson(json);
    });
  }

  @override
  Future<OrderDocumentation> uploadDocumentation({
    required String orderId,
    required DocumentationType type,
    required String imagePath,
    String? orderItemId,
  }) {
    return _guard(() async {
      final json = await api.postMultipart(
        ApiEndpoints.orderDocumentations(orderId),
        auth: true,
        fields: {
          'type': type.json,
          if (orderItemId != null) 'order_item_id': orderItemId,
        },
        fileField: 'image',
        filePath: imagePath,
      );
      return orderDocumentationFromJson(json);
    });
  }

  @override
  Future<void> deleteDocumentation({
    required String orderId,
    required String documentationId,
  }) {
    return _guard(() async {
      await api.delete(
        ApiEndpoints.orderDocumentation(orderId, documentationId),
        auth: true,
      );
    });
  }

  @override
  Future<List<AssignableWorker>> fetchAssignableWorkers() {
    return _guard(() async {
      final json = await api.get(ApiEndpoints.workers, auth: true);
      final raw = json['items'] as List<dynamic>? ?? const [];
      return [for (final item in raw) assignableWorkerFromJson(item as Json)];
    });
  }

  Future<T> _guard<T>(Future<T> Function() run) async {
    try {
      return await run();
    } on AppException catch (e) {
      throw _toFailure(e);
    }
  }

  Failure _toFailure(AppException e) {
    if (e.isNetwork) {
      return Failure(FailureType.network, e.message, code: e.code);
    }
    switch (e.statusCode) {
      case 401:
        return Failure(FailureType.unauthorized, e.message, code: e.code);
      case 409:
        return Failure(FailureType.conflict, e.message, code: e.code);
      case 400:
      case 403:
      case 404:
      case 413:
      case 415:
        return Failure(FailureType.validation, e.message, code: e.code);
    }
    if ((e.statusCode ?? 0) >= 500) {
      return Failure(FailureType.server, e.message, code: e.code);
    }
    return Failure(
      FailureType.unknown,
      e.message.isEmpty ? AppStrings.errUnknown : e.message,
      code: e.code,
    );
  }
}
