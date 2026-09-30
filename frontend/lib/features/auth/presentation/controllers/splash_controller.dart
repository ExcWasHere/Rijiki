import 'package:flutter_riverpod/flutter_riverpod.dart';
import '/../app/providers.dart';
import '/../app/router/role_redirect.dart';
import '/../core/constants/app_constants.dart';
import '/../core/session/session_provider.dart';

/// Menjalankan proses startup: pulihkan sesi, isi `sessionProvider`, lalu
/// menentukan rute tujuan.
///
/// State-nya `AsyncValue<String>`:
/// - loading -> splash tampil (animasi berjalan)
/// - data    -> rute tujuan (page melakukan `context.go`)
/// - error   -> `Failure`, page menampilkan tombol coba lagi
final splashControllerProvider =
    AsyncNotifierProvider.autoDispose<SplashController, String>(
  SplashController.new,
);

class SplashController extends AutoDisposeAsyncNotifier<String> {
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