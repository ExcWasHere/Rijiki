import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:rijiki/core/constants/app_constants.dart';
import 'package:rijiki/core/network/api_client.dart';
import 'package:rijiki/core/session/session_provider.dart';
import 'package:rijiki/core/storage/token_storage.dart';
import 'package:rijiki/features/auth/data/auth_repository_impl.dart';
import 'package:rijiki/features/auth/data/google_sign_in_service.dart';
import 'package:rijiki/features/auth/data/mock_auth_repo.dart';
import 'package:rijiki/features/auth/domain/auth_repo.dart';

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
