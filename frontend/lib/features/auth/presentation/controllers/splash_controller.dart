import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:rijiki/app/providers.dart';
import 'package:rijiki/app/router/role_redirect.dart';
import 'package:rijiki/core/constants/app_constants.dart';
import 'package:rijiki/core/session/session_provider.dart';

final splashControllerProvider =
    AsyncNotifierProvider.autoDispose<SplashController, String>(
  SplashController.new,
);

class SplashController extends AsyncNotifier<String> {
  @override
  Future<String> build() async {
    final repository = ref.read(authRepositoryProvider);

    final userFuture = repository.restoreSession();
    final minDuration = Future<void>.delayed(AppConstants.splashMinDuration);

    final user = await userFuture;
    await minDuration;

    ref.read(sessionProvider.notifier).setUser(user);
    return RoleRedirect.entryRoute(user);
  }

  void retry() => ref.invalidateSelf();
}
