abstract final class ApiEndpoints {
  static const String register = '/api/auth/register';
  static const String verifyEmail = '/api/auth/verify-email';
  static const String resendVerification = '/api/auth/resend-verification';
  static const String login = '/api/auth/login';
  static const String google = '/api/auth/google';
  static const String refresh = '/api/auth/refresh';
  static const String me = '/api/auth/me';
  static const String logout = '/api/auth/logout';

  static const String profile = '/api/profile';

  static const String services = '/api/services';

  static const String orders = '/api/orders';
  static const String orderQuote = '/api/orders/quote';
  static String orderById(String id) => '$orders/$id';
  static String orderClaim(String id) => '$orders/$id/claim';
  static String orderAssign(String id) => '$orders/$id/assign';
  static String orderStatus(String id) => '$orders/$id/status';
  static String orderDocumentations(String id) => '$orders/$id/documentations';
  static String orderDocumentation(String id, String docId) =>
      '$orders/$id/documentations/$docId';

  /// Kurir mengirim titik (POST) dan customer/staff membaca posisi (GET).
  static String orderTracking(String id) => '$orders/$id/tracking';

  static const String workers = '/api/workers';

  /// Foto privat (dokumentasi order, dst.) - butuh header Authorization.
  static String privateMedia(String key) => '/api/media/private/$key';
}
