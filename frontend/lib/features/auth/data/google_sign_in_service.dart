import 'package:google_sign_in/google_sign_in.dart';
import 'package:rijiki/core/constants/app_strings.dart';
import 'package:rijiki/core/error/failure.dart';

class GoogleSignInService {
  GoogleSignInService({required this.serverClientId});

  final String serverClientId;

  bool _initialized = false;

  Future<void> _ensureInitialized() async {
    if (_initialized) return;
    await GoogleSignIn.instance.initialize(serverClientId: serverClientId);
    _initialized = true;
  }

  Future<String?> signIn() async {
    if (serverClientId.isEmpty) {
      throw const Failure(FailureType.unknown, AppStrings.errGoogleNotConfigured);
    }

    try {
      await _ensureInitialized();
      final account = await GoogleSignIn.instance.authenticate();
      final idToken = account.authentication.idToken;
      if (idToken == null || idToken.isEmpty) {
        throw const Failure(FailureType.unknown, AppStrings.errGoogleFailed);
      }
      return idToken;
    } on GoogleSignInException catch (e) {
      return _handleException(e);
    } on Failure {
      rethrow;
    } catch (_) {
      throw const Failure(FailureType.unknown, AppStrings.errGoogleFailed);
    }
  }

  Future<void> signOut() async {
    if (serverClientId.isEmpty) return;
    try {
      await _ensureInitialized();
      await GoogleSignIn.instance.signOut();
    } catch (_) {
    }
  }

  String? _handleException(GoogleSignInException e) {
    final isReauthConfigIssue = (e.description ?? '').contains('[16]');

    if (e.code == GoogleSignInExceptionCode.canceled && !isReauthConfigIssue) {
      return null;
    }
    if (e.code == GoogleSignInExceptionCode.interrupted) return null;

    if (isReauthConfigIssue ||
        e.code == GoogleSignInExceptionCode.clientConfigurationError ||
        e.code == GoogleSignInExceptionCode.providerConfigurationError) {
      throw const Failure(FailureType.unknown, AppStrings.errGoogleConfig);
    }
    throw const Failure(FailureType.unknown, AppStrings.errGoogleFailed);
  }
}
