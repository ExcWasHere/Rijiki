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

  static const String workerHome = '/worker';
  static const String ownerHome = '/owner';

  static String verifyEmailFor(String email) {
    return Uri(path: verifyEmail, queryParameters: {'email': email}).toString();
  }
}
