abstract final class RoutePaths {
  static const String splash = '/splash';
  static const String landing = '/landing';
  static const String login = '/login';
  static const String register = '/register';
  static const String verifyEmail = '/verify-email';
  static const String onboarding = '/onboarding';

  static const String editProfile = '/profile/edit';
  
  static const String accountSecurity = '/profile/security';
  static const String changePassword = '/profile/security/password';
  static const String changeEmail = '/profile/security/email';

  static const String customerHome = '/customer';
  static const String customerOrders = '/customer/orders';
  static const String customerEvents = '/customer/events';
  static const String customerProfile = '/customer/profile';

  static const String customerScan = '/customer/scan';
  static const String customerScanAnalyzing = '/customer/scan/analyzing';
  static const String customerScanResult = '/customer/scan/result';

  static const String orderCreate = '/customer/orders/new';
  static const String orderSummary = '/customer/orders/new/summary';

  static const workerHome = '/worker';
  static const workerOrders = '/worker/orders';
  static const workerManagement = '/worker/management';
  static const workerProfile = '/worker/profile';
  static const String workerOfflineOrder = '/worker/orders/offline/new';
  static const String workerDeliveryRun = '/worker/orders/delivery';

  static const String ownerHome = '/owner';
  static const String ownerOrders = '/owner/orders';
  static const String ownerManagement = '/owner/management';
  static const String ownerProfile = '/owner/profile';
  static const String ownerRepeatCustomers = '/owner/repeat-customers';

  static const String ownerFinance = '/owner/management/finance';
  static const String ownerFinanceTransactions =
      '/owner/management/finance/transactions';
  static const String ownerFinanceExpenseAi =
      '/owner/management/finance/expenses/ai';
  static const String ownerFinanceExpenseReview =
      '/owner/management/finance/expenses/ai/review';
  static const String ownerFinanceIncomeNew =
      '/owner/management/finance/income/new';
  static const String ownerManagementRepeatCustomers =
      '/owner/management/repeat-customers';

  static const String ownerWorkers = '/management/workers';
  static const String ownerWorkerNew = '/management/workers/new';
  static const String ownerWorkerKpiOverview = '/management/workers/kpi';

  static const String managementRepeatCustomers =
      '/management/repeat-customers';

  static const String managementPoints = '/management/points';
  static const String managementPointRedemptions =
      '/management/points/redemptions';
  static const String managementPointAdjust = '/management/points/adjust';

  static String ownerWorkerDetailFor(String workerId) =>
      '$ownerWorkers/$workerId';
  static String ownerWorkerEditFor(String workerId) =>
      '$ownerWorkers/$workerId/edit';
  static String ownerWorkerAccessFor(String workerId) =>
      '$ownerWorkers/$workerId/access';
  static String ownerWorkerKpiAssessFor(String workerId, int month, int year) =>
      Uri(
        path: '$ownerWorkers/$workerId/kpi',
        queryParameters: {'month': '$month', 'year': '$year'},
      ).toString();

  static const String ownerCms = '/management/cms';
  static const String ownerCmsServices = '/management/cms/services';
  static const String ownerCmsServiceNew = '/management/cms/services/new';

  static String ownerCmsServiceEditFor(String serviceId) =>
      '$ownerCmsServices/$serviceId/edit';

  static const String ownerCmsEvents = '/management/cms/events';
  static const String ownerCmsEventNew = '/management/cms/events/new';

  static String ownerCmsEventEditFor(String eventId) =>
      '$ownerCmsEvents/$eventId/edit';

  static const String ownerCmsPromos = '/management/cms/promos';
  static const String ownerCmsPromoNew = '/management/cms/promos/new';

  static String ownerCmsPromoEditFor(String promoId) =>
      '$ownerCmsPromos/$promoId/edit';

  static const String ownerCmsMerchandise = '/management/cms/merchandise';
  static const String ownerCmsMerchandiseNew =
      '/management/cms/merchandise/new';

  static String ownerCmsMerchandiseEditFor(String merchandiseId) =>
      '$ownerCmsMerchandise/$merchandiseId/edit';

  static const String ownerCmsPoints = '/management/cms/points';
  static const String ownerCmsTestimonials =
      '/management/cms/testimonials';

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
  static String ratingFor(String orderId) =>
      '$customerOrders/$orderId/rating';

  static String paymentResultFor(String orderId, String status) => Uri(
    path: '$customerOrders/$orderId/pay/result',
    queryParameters: {'status': status},
  ).toString();

  static String workerOrderDetailFor(String orderId) =>
    '$workerOrders/$orderId';
  static String workerOrderPaymentFor(String orderId) =>
    '$workerOrders/$orderId/pay';
  static String ownerOrderPaymentFor(String orderId) =>
    '$ownerOrders/$orderId/pay';
  static String ownerOrderDetailFor(String orderId) => '$ownerOrders/$orderId';
}