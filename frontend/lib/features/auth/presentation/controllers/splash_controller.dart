import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:rijiki/app/providers.dart';
import 'package:rijiki/app/router/role_redirect.dart';
import 'package:rijiki/core/constants/app_constants.dart';
import 'package:rijiki/core/session/app_user.dart';
import 'package:rijiki/core/session/session_provider.dart';

final splashControllerProvider =
    AsyncNotifierProvider.autoDispose<SplashController, String>(
      SplashController.new,
      retry: (retryCount, error) => null,
    );

class SplashController extends AsyncNotifier<String> {
  static const Duration _minFailureDuration = Duration(milliseconds: 900);

  @override
  Future<String> build() async {
    final repository = ref.read(authRepositoryProvider);
    final minDuration = Future<void>.delayed(AppConstants.splashMinDuration);

    final AppUser? user;
    try {
      user = await repository.restoreSession();
    } catch (_) {
      await Future<void>.delayed(_minFailureDuration);
      rethrow;
    }
    await minDuration;

    ref.read(sessionProvider.notifier).setUser(user);
    return RoleRedirect.entryRoute(user);
  }

  void retry() => ref.invalidateSelf();
}
