abstract final class RoutePaths {
  static const String splash = '/splash';
  static const String landing = '/landing';
  static const String login = '/login';
  static const String register = '/register';
  static const String verifyEmail = '/verify-email';
  static const String onboarding = '/onboarding';

  // Di luar shell supaya bottom navbar tersembunyi; dipakai semua role.
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

  static const String ownerWorkers = '/owner/management/workers';
  static const String ownerWorkerNew = '/owner/management/workers/new';
  static const String ownerWorkerKpiOverview = '/owner/management/workers/kpi';

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

  static const String ownerCms = '/owner/management/cms';
  static const String ownerCmsServices = '/owner/management/cms/services';
  static const String ownerCmsServiceNew = '/owner/management/cms/services/new';

  static String ownerCmsServiceEditFor(String serviceId) =>
      '$ownerCmsServices/$serviceId/edit';

  static const String ownerCmsEvents = '/owner/management/cms/events';
  static const String ownerCmsEventNew = '/owner/management/cms/events/new';

  static String ownerCmsEventEditFor(String eventId) =>
      '$ownerCmsEvents/$eventId/edit';

  static const String ownerCmsPromos = '/owner/management/cms/promos';
  static const String ownerCmsPromoNew = '/owner/management/cms/promos/new';

  static String ownerCmsPromoEditFor(String promoId) =>
      '$ownerCmsPromos/$promoId/edit';

  static const String ownerCmsMerchandise = '/owner/management/cms/merchandise';
  static const String ownerCmsMerchandiseNew =
      '/owner/management/cms/merchandise/new';

  static String ownerCmsMerchandiseEditFor(String merchandiseId) =>
      '$ownerCmsMerchandise/$merchandiseId/edit';

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

  static String workerOrderDetailFor(String orderId) =>
      '$workerOrders/$orderId';
  static String ownerOrderDetailFor(String orderId) => '$ownerOrders/$orderId';
}