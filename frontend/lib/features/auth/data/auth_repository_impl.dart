import 'package:rijiki/core/constants/app_strings.dart';
import 'package:rijiki/core/error/app_exception.dart';
import 'package:rijiki/core/error/failure.dart';
import 'package:rijiki/core/network/api_client.dart';
import 'package:rijiki/core/network/api_endpoint.dart';
import 'package:rijiki/core/session/app_user.dart';
import 'package:rijiki/core/storage/token_storage.dart';
import 'package:rijiki/features/auth/domain/auth_repo.dart';

class AuthRepositoryImpl implements AuthRepository {
  AuthRepositoryImpl({required this.api, required this.tokens});

  final ApiClient api;
  final TokenStorage tokens;

  @override
  Future<AppUser?> restoreSession() async {
    if (!await tokens.hasSession()) return null;

    try {
      final json = await api.get(ApiEndpoints.me, auth: true);
      return AppUser.fromAuthJson(json);
    } on AppException catch (e) {
      if (e.statusCode == 401 || e.statusCode == 403) {
        await tokens.clear();
        return null;
      }
      throw _toFailure(e);
    }
  }

  @override
  Future<AppUser> login({required String email, required String password}) {
    return _authenticate(
      ApiEndpoints.login,
      {'email': email, 'password': password},
    );
  }

  @override
  Future<void> register({required String email, required String password}) async {
    try {
      await api.post(
        ApiEndpoints.register,
        body: {'email': email, 'password': password},
      );
    } on AppException catch (e) {
      throw _toFailure(e);
    }
  }

  @override
  Future<AppUser> verifyEmail({required String email, required String code}) {
    return _authenticate(
      ApiEndpoints.verifyEmail,
      {'email': email, 'code': code},
    );
  }

  @override
  Future<void> resendVerification({required String email}) async {
    try {
      await api.post(ApiEndpoints.resendVerification, body: {'email': email});
    } on AppException catch (e) {
      throw _toFailure(e);
    }
  }

  @override
  Future<void> logout() async {
    try {
      await api.post(ApiEndpoints.logout, auth: true);
    } on AppException {
      // Gagal mencabut sesi di server tidak boleh menahan logout lokal.
    } finally {
      await tokens.clear();
    }
  }

  Future<AppUser> _authenticate(String path, Map<String, dynamic> body) async {
    try {
      final json = await api.post(path, body: body);
      await tokens.save(
        accessToken: json['access_token'] as String,
        refreshToken: json['refresh_token'] as String,
      );
      return AppUser.fromAuthJson(json);
    } on AppException catch (e) {
      throw _toFailure(e);
    }
  }

  Failure _toFailure(AppException e) {
    switch (e.code) {
      case AppException.networkCode:
        return Failure(FailureType.network, e.message, code: e.code);
      case 'email_not_verified':
        return Failure(FailureType.emailNotVerified, e.message, code: e.code);
      case 'invalid_credentials':
      case 'unauthorized':
        return Failure(FailureType.unauthorized, e.message, code: e.code);
      case 'invalid_otp':
        return Failure(FailureType.invalidOtp, e.message, code: e.code);
      case 'email_already_registered':
        return Failure(FailureType.conflict, e.message, code: e.code);
      case 'rate_limited':
        return Failure(FailureType.rateLimited, e.message, code: e.code);
      case 'validation_error':
        return Failure(FailureType.validation, e.message, code: e.code);
    }
    if ((e.statusCode ?? 0) >= 500) {
      return Failure(FailureType.server, e.message, code: e.code);
    }
    return Failure(
      FailureType.unknown,
      e.message.isEmpty ? AppStrings.errUnknown : e.message,
      code: e.code,
    );
  }
}
