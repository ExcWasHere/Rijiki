import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:rijiki/core/constants/app_constants.dart';
import 'package:rijiki/core/mock/mock_scenario.dart';
import 'package:rijiki/core/network/api_client.dart';
import 'package:rijiki/core/session/session_provider.dart';
import 'package:rijiki/core/storage/token_storage.dart';
import 'package:rijiki/features/auth/data/auth_repository_impl.dart';
import 'package:rijiki/features/auth/data/google_sign_in_service.dart';
import 'package:rijiki/features/auth/data/mock_auth_repo.dart';
import 'package:rijiki/features/auth/domain/auth_repo.dart';
import 'package:rijiki/features/event/data/mock_event_repository.dart';
import 'package:rijiki/features/event/domain/event_repository.dart';
import 'package:rijiki/features/order/data/mock_order_repository.dart';
import 'package:rijiki/features/order/domain/order_repository.dart';
import 'package:rijiki/features/rating/data/mock_rating_repository.dart';
import 'package:rijiki/features/rating/domain/rating_repository.dart';
import 'package:rijiki/features/scan/data/mock_scan_repository.dart';
import 'package:rijiki/features/scan/domain/scan_repository.dart';
import 'package:rijiki/features/service/data/mock_service_repository.dart';
import 'package:rijiki/features/service/domain/service_repository.dart';

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
final mockScenarioProvider = Provider<MockScenario>((ref) => MockScenario.data);

final serviceRepositoryProvider = Provider<ServiceRepository>(
  (ref) => MockServiceRepository(scenario: ref.watch(mockScenarioProvider)),
);

final eventRepositoryProvider = Provider<EventRepository>(
  (ref) => MockEventRepository(scenario: ref.watch(mockScenarioProvider)),
);

final orderRepositoryProvider = Provider<OrderRepository>(
  (ref) => MockOrderRepository(scenario: ref.watch(mockScenarioProvider)),
);

final ratingRepositoryProvider = Provider<RatingRepository>(
  (ref) => MockRatingRepository(scenario: ref.watch(mockScenarioProvider)),
);

final scanRepositoryProvider = Provider<ScanRepository>(
  (ref) => MockScanRepository(scenario: ref.watch(mockScenarioProvider)),
);