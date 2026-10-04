abstract final class RoutePaths {
  static const String splash = '/splash';
  static const String login = '/login';
  static const String register = '/register';
  static const String verifyEmail = '/verify-email';
  static const String onboarding = '/onboarding';
  static const String customerHome = '/customer';
  static const String workerHome = '/worker';
  static const String ownerHome = '/owner';

  static String verifyEmailFor(String email) {
    return Uri(path: verifyEmail, queryParameters: {'email': email}).toString();
  }
}
