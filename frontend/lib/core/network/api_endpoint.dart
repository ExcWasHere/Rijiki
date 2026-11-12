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

  static const String promos = '/api/promos';
  static String promoById(String id) => '$promos/$id';

  /// Customer: event/promo/kolaborasi yang sedang tayang.
  static const String events = '/api/events';

  /// Owner atau worker berizin manage_cms_events.
  static const String managementEvents = '/api/management/events';
  static String managementEventById(String id) => '$managementEvents/$id';
  static const String managementEventPromoOptions =
      '$managementEvents/promo-options';

  /// Unggah banner event ke R2 (multipart, field `image`).
  static const String eventBanner = '/api/media/event-banner';

  /// Customer: saldo dan riwayat poin.
  static const String pointBalance = '/api/points/balance';
  static const String pointLedger = '/api/points/ledger';

  /// Customer: hadiah yang bisa ditukar poin, dan pengajuan penukarannya.
  static const String pointRewards = '/api/points/rewards';
  static const String pointRedemptions = '/api/points/redemptions';

  /// Owner atau worker berizin manage_cms_merchandise.
  static const String managementMerchandise = '/api/management/merchandise';
  static String managementMerchandiseById(String id) =>
      '$managementMerchandise/$id';

  /// Unggah foto merchandise ke R2 (multipart, field `image`).
  static const String merchandiseImage = '/api/media/merchandise-image';

  static const String pointRules = '/api/management/point-rules';
  static String pointRuleById(String id) => '$pointRules/$id';

  static const String managementPointRedemptions =
      '/api/management/points/redemptions';
  static String managementPointRedemption(String id) =>
      '$managementPointRedemptions/$id';
  static const String managementPointCustomers =
      '/api/management/points/customers';
  static const String managementPointAdjust = '/api/management/points/adjust';

  static const String repeatCustomers = '/api/management/customers/repeat';

  static const String orders = '/api/orders';
  static const String orderQuote = '/api/orders/quote';

  /// Order offline (POS) di outlet; worker atau owner.
  static const String orderOffline = '/api/orders/offline';
  static String orderById(String id) => '$orders/$id';
  static String orderClaim(String id) => '$orders/$id/claim';
  static String orderAssign(String id) => '$orders/$id/assign';
  static String orderStatus(String id) => '$orders/$id/status';
  static String orderDocumentations(String id) => '$orders/$id/documentations';
  static String orderDocumentation(String id, String docId) =>
      '$orders/$id/documentations/$docId';

  static String orderTracking(String id) => '$orders/$id/tracking';
  static String orderRating(String id) => '$orders/$id/rating';

  /// Membuat QR QRIS untuk order (idempoten: QR aktif dipakai lagi).
  static String orderPayment(String id) => '$orders/$id/payment';

  /// Status pembayaran; dipakai polling halaman QRIS.
  static String paymentById(String id) => '/api/payments/$id';

  static const String testimonialsFeatured = '/api/testimonials/featured';
  static const String managementTestimonials = '/api/management/testimonials';
  static const String managementTestimonialsExport =
      '/api/management/testimonials/export';
  static String managementTestimonialFeatured(String id) =>
      '$managementTestimonials/$id/featured';

  static const String workers = '/api/workers';
  static const String workersKpiOverview = '/api/workers/kpi-overview';
  static String workerReviews(String id) => '$workers/$id/reviews';
  static String workerKpi(String id) => '$workers/$id/kpi';
  static String workerPermissions(String id) => '/api/owner/workers/$id/permissions';

  static const String avatar = '/api/media/avatar';
  static String privateMedia(String key) => '/api/media/private/$key';
}
