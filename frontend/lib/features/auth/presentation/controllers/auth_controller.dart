import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:rijiki/app/providers.dart';
import 'package:rijiki/core/constants/app_strings.dart';
import 'package:rijiki/core/error/failure.dart';
import 'package:rijiki/core/session/session_provider.dart';
import 'package:rijiki/features/auth/domain/auth_repo.dart';

enum LoginOutcome { success, needsVerification, failed }
final authControllerProvider =
    AsyncNotifierProvider.autoDispose<AuthController, void>(
  AuthController.new,
);

class AuthController extends AsyncNotifier<void> {
  @override
  Future<void> build() async {}

  Future<LoginOutcome> login({
    required String email,
    required String password,
  }) async {
    final repository = ref.read(authRepositoryProvider);
    final session = ref.read(sessionProvider.notifier);

    _set(const AsyncLoading());
    try {
      final user = await repository.login(email: email, password: password);
      session.setUser(user);
      _set(const AsyncData(null));
      return LoginOutcome.success;
    } on Failure catch (failure, stack) {
      if (failure.type == FailureType.emailNotVerified) {
        await _tryResend(repository, email);
        _set(const AsyncData(null));
        return LoginOutcome.needsVerification;
      }
      _set(AsyncError(failure, stack));
      return LoginOutcome.failed;
    } catch (_, stack) {
      _set(AsyncError(const Failure(FailureType.unknown, AppStrings.errUnknown), stack));
      return LoginOutcome.failed;
    }
  }

  Future<bool> register({required String email, required String password}) async {
    final repository = ref.read(authRepositoryProvider);
    final ok = await _run(() async {
      await repository.register(email: email, password: password);
      return true;
    });
    return ok ?? false;
  }

  Future<bool> verifyEmail({required String email, required String code}) async {
    final repository = ref.read(authRepositoryProvider);
    final session = ref.read(sessionProvider.notifier);

    final user = await _run(
      () => repository.verifyEmail(email: email, code: code),
    );
    if (user == null) return false;
    session.setUser(user);
    return true;
  }

  Future<bool> resendVerification({required String email}) async {
    final repository = ref.read(authRepositoryProvider);
    final ok = await _run(() async {
      await repository.resendVerification(email: email);
      return true;
    });
    return ok ?? false;
  }

  Future<void> logout() async {
    final repository = ref.read(authRepositoryProvider);
    final session = ref.read(sessionProvider.notifier);

    _set(const AsyncLoading());
    try {
      await repository.logout();
    } finally {
      session.clear();
    }
    _set(const AsyncData(null));
  }

  Future<T?> _run<T>(Future<T> Function() action) async {
    _set(const AsyncLoading());
    try {
      final result = await action();
      _set(const AsyncData(null));
      return result;
    } on Failure catch (failure, stack) {
      _set(AsyncError(failure, stack));
      return null;
    } catch (_, stack) {
      _set(AsyncError(const Failure(FailureType.unknown, AppStrings.errUnknown), stack));
      return null;
    }
  }

  Future<void> _tryResend(AuthRepository repository, String email) async {
    try {
      await repository.resendVerification(email: email);
    } on Failure {
      // hmm
    }
  }

  void _set(AsyncValue<void> value) {
    if (ref.mounted) state = value;
  }
}