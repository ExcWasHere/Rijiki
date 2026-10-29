import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:rijiki/core/constants/app_constants.dart';
import 'package:rijiki/core/mock/mock_scenario.dart';
import 'package:rijiki/core/network/api_client.dart';
import 'package:rijiki/core/session/session_provider.dart';
import 'package:rijiki/core/storage/token_storage.dart';
import 'package:rijiki/features/access_control/data/mock_permission_repository.dart';
import 'package:rijiki/features/access_control/domain/permission_repository.dart';
import 'package:rijiki/features/auth/data/auth_repository_impl.dart';
import 'package:rijiki/features/auth/data/google_sign_in_service.dart';
import 'package:rijiki/features/auth/data/mock_auth_repo.dart';
import 'package:rijiki/features/auth/domain/auth_repo.dart';
import 'package:rijiki/features/finance/data/mock_finance_repository.dart';
import 'package:rijiki/features/finance/domain/finance_repository.dart';
import 'package:rijiki/features/home/owner/data/mock_dashboard_repository.dart';
import 'package:rijiki/features/home/owner/domain/dashboard_repository.dart';
import 'package:rijiki/features/event/data/mock_event_repository.dart';
import 'package:rijiki/features/event/data/mock_promo_repository.dart';
import 'package:rijiki/features/event/domain/event_repository.dart';
import 'package:rijiki/features/event/domain/promo_repository.dart';
import 'package:rijiki/features/merchandise/data/mock_merchandise_repository.dart';
import 'package:rijiki/features/merchandise/domain/merchandise_repository.dart';
import 'package:rijiki/features/order/data/mock_order_repository.dart';
import 'package:rijiki/features/order/data/courier_tracking_repository_impl.dart';
import 'package:rijiki/features/order/data/mock_staff_order_repository.dart';
import 'package:rijiki/features/order/data/order_repository_impl.dart';
import 'package:rijiki/features/order/data/staff_order_repository_impl.dart';
import 'package:rijiki/features/order/domain/courier_tracking_repository.dart';
import 'package:rijiki/features/order/domain/order_repository.dart';
import 'package:rijiki/features/order/domain/staff_order_repository.dart';
import 'package:rijiki/features/payment/data/mock_payment_repository.dart';
import 'package:rijiki/features/payment/domain/payment_repository.dart';
import 'package:rijiki/features/profile/data/mock_profile_repository.dart';
import 'package:rijiki/features/profile/data/profile_repository_impl.dart';
import 'package:rijiki/features/profile/domain/profile_repository.dart';
import 'package:rijiki/features/rating/data/mock_rating_repository.dart';
import 'package:rijiki/features/rating/domain/rating_repository.dart';
import 'package:rijiki/features/scan/data/mock_scan_repository.dart';
import 'package:rijiki/features/scan/domain/scan_repository.dart';
import 'package:rijiki/features/service/data/mock_service_repository.dart';
import 'package:rijiki/features/service/data/service_repository_impl.dart';
import 'package:rijiki/features/service/domain/service_repository.dart';
import 'package:rijiki/features/worker_management/data/mock_worker_repository.dart';
import 'package:rijiki/features/worker_management/domain/worker_repository.dart';

final tokenStorageProvider = Provider<TokenStorage>((ref) => TokenStorage());

final googleSignInServiceProvider = Provider<GoogleSignInService>((ref) {
  return GoogleSignInService(serverClientId: AppConstants.googleServerClientId);
});

final apiClientProvider = Provider<ApiClient>((ref) {
  return ApiClient(
    baseUrl: AppConstants.apiBaseUrl,
    tokenStorage: ref.watch(tokenStorageProvider),
    onSessionExpired: () => ref.read(sessionProvider.notifier).clear(),
  );
});

final authRepositoryProvider = Provider<AuthRepository>((ref) {
  if (AppConstants.useMockAuth) return MockAuthRepository();
  return AuthRepositoryImpl(
    api: ref.watch(apiClientProvider),
    tokens: ref.watch(tokenStorageProvider),
    googleSignIn: ref.watch(googleSignInServiceProvider),
  );
});

final profileRepositoryProvider = Provider<ProfileRepository>((ref) {
  if (AppConstants.useMockAuth) return MockProfileRepository();
  return ProfileRepositoryImpl(api: ref.watch(apiClientProvider));
});

final mockScenarioProvider = Provider<MockScenario>((ref) => MockScenario.data);

final serviceRepositoryProvider = Provider<ServiceRepository>((ref) {
  final mock = MockServiceRepository(scenario: ref.watch(mockScenarioProvider));
  if (AppConstants.useMockOrders) return mock;
  return ServiceRepositoryImpl(api: ref.watch(apiClientProvider), cms: mock);
});

final eventRepositoryProvider = Provider<EventRepository>(
  (ref) => MockEventRepository(scenario: ref.watch(mockScenarioProvider)),
);

final promoRepositoryProvider = Provider<PromoRepository>(
  (ref) => MockPromoRepository(scenario: ref.watch(mockScenarioProvider)),
);

final merchandiseRepositoryProvider = Provider<MerchandiseRepository>(
  (ref) => MockMerchandiseRepository(scenario: ref.watch(mockScenarioProvider)),
);

final orderRepositoryProvider = Provider<OrderRepository>((ref) {
  if (AppConstants.useMockOrders) {
    return MockOrderRepository(
      promos: ref.watch(promoRepositoryProvider),
      scenario: ref.watch(mockScenarioProvider),
    );
  }
  return OrderRepositoryImpl(api: ref.watch(apiClientProvider));
});

final staffOrderRepositoryProvider = Provider<StaffOrderRepository>((ref) {
  if (AppConstants.useMockOrders) {
    return MockStaffOrderRepository(orders: ref.watch(orderRepositoryProvider));
  }
  return StaffOrderRepositoryImpl(api: ref.watch(apiClientProvider));
});

final courierTrackingRepositoryProvider = Provider<CourierTrackingRepository>(
  (ref) => CourierTrackingRepositoryImpl(api: ref.watch(apiClientProvider)),
);

final ratingRepositoryProvider = Provider<RatingRepository>(
  (ref) => MockRatingRepository(scenario: ref.watch(mockScenarioProvider)),
);

final scanRepositoryProvider = Provider<ScanRepository>(
  (ref) => MockScanRepository(scenario: ref.watch(mockScenarioProvider)),
);

final paymentRepositoryProvider = Provider<PaymentRepository>(
  (ref) => MockPaymentRepository(
    orders: ref.watch(orderRepositoryProvider),
    scenario: ref.watch(mockScenarioProvider),
  ),
);

final dashboardRepositoryProvider = Provider<DashboardRepository>(
  (ref) => MockDashboardRepository(),
);

final financeRepositoryProvider = Provider<FinanceRepository>(
  (ref) => MockFinanceRepository(
    dashboard: ref.watch(dashboardRepositoryProvider),
  ),
);

final workerRepositoryProvider = Provider<WorkerRepository>(
  (ref) => MockWorkerRepository(scenario: ref.watch(mockScenarioProvider)),
);

final permissionRepositoryProvider = Provider<PermissionRepository>(
  (ref) => MockPermissionRepository(scenario: ref.watch(mockScenarioProvider)),
);
