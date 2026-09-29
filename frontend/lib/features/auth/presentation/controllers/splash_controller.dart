import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../app/providers.dart';
import '../../../../app/router/role_redirect.dart';
import '../../../../core/constants/app_constants.dart';
import '../../../../core/session/session_provider.dart';

/// State: loading -> splash tampil, data -> rute tujuan, error -> Failure.
final splashControllerProvider =
    AsyncNotifierProvider.autoDispose<SplashController, String>(
      SplashController.new,
    );

class SplashController extends AutoDisposeAsyncNotifier<String> {
  @override
  Future<String> build() async {
    final repository = ref.read(authRepositoryProvider);

    // Pulihkan sesi dan tahan durasi minimum secara paralel.
    final userFuture = repository.restoreSession();
    final minDuration = Future<void>.delayed(AppConstants.splashMinDuration);

    final user = await userFuture;
    await minDuration;

    ref.read(sessionProvider.notifier).setUser(user);
    return RoleRedirect.entryRoute(user);
  }

  void retry() => ref.invalidateSelf();
}
