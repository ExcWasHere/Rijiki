abstract final class RoutePaths {
  static const String splash = '/splash';
  static const String login = '/login';
  static const String register = '/register';
  static const String verifyEmail = '/verify-email';
  static const String onboarding = '/onboarding';

  static const String customerHome = '/customer';
  static const String customerOrders = '/customer/orders';
  static const String customerEvents = '/customer/events';
  static const String customerProfile = '/customer/profile';

  static const String customerScan = '/customer/scan';
  static const String customerScanAnalyzing = '/customer/scan/analyzing';
  static const String customerScanResult = '/customer/scan/result';

  static const String orderCreate = '/customer/orders/new';
  static const String orderSummary = '/customer/orders/new/summary';

  static const String workerHome = '/worker';

  static const String ownerHome = '/owner';
  static const String ownerOrders = '/owner/orders';
  static const String ownerManagement = '/owner/management';
  static const String ownerProfile = '/owner/profile';
  static const String ownerRepeatCustomers = '/owner/repeat-customers';

  static String verifyEmailFor(String email) {
    return Uri(path: verifyEmail, queryParameters: {'email': email}).toString();
  }

  static String orderCreateFor({String? serviceId}) {
    return Uri(
      path: orderCreate,
      queryParameters: serviceId == null ? null : {'serviceId': serviceId},
    ).toString();
  }

  static String orderDetailFor(String orderId) => '$customerOrders/$orderId';
  static String orderTrackingFor(String orderId) =>
      '$customerOrders/$orderId/tracking';
  static String orderPaymentFor(String orderId) =>
      '$customerOrders/$orderId/pay';
  static String receiptFor(String orderId) =>
      '$customerOrders/$orderId/receipt';
  static String deliveryMapFor(String orderId) =>
      '$customerOrders/$orderId/map';

  static String paymentResultFor(String orderId, String status) => Uri(
    path: '$customerOrders/$orderId/pay/result',
    queryParameters: {'status': status},
  ).toString();
}
