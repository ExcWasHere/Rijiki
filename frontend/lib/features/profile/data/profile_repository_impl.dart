import 'package:rijiki/core/constants/app_strings.dart';
import 'package:rijiki/core/error/app_exception.dart';
import 'package:rijiki/core/error/failure.dart';
import 'package:rijiki/core/network/api_client.dart';
import 'package:rijiki/core/network/api_endpoint.dart';
import 'package:rijiki/core/session/app_user.dart';
import 'package:rijiki/features/profile/domain/profile_repository.dart';

class ProfileRepositoryImpl implements ProfileRepository {
  ProfileRepositoryImpl({required this.api});

  final ApiClient api;

  @override
  Future<AppUser> saveCustomerProfile({
    required AppUser currentUser,
    required String fullName,
    required String phoneNumber,
    required String address,
    required double latitude,
    required double longitude,
  }) async {
    try {
      final json = await api.patch(
        ApiEndpoints.profile,
        auth: true,
        body: {
          'full_name': fullName,
          'phone_number': phoneNumber,
          'default_address': address,
          'default_lat': latitude,
          'default_lng': longitude,
        },
      );
      return AppUser.fromAuthJson(json);
    } on AppException catch (e) {
      throw _toFailure(e);
    }
  }

  @override
  Future<AppUser> saveProfile({
    required AppUser currentUser,
    required String fullName,
    required String phoneNumber,
  }) async {
    try {
      final json = await api.patch(
        ApiEndpoints.profile,
        auth: true,
        body: {'full_name': fullName, 'phone_number': phoneNumber},
      );
      // Jangan pakai hasil parse langsung: respons PATCH belum tentu memuat
      // permissions/owner_bypass, sehingga izin worker/owner bisa hilang.
      final parsed = AppUser.fromAuthJson(json);
      return currentUser.copyWith(
        fullName: parsed.fullName,
        phoneNumber: parsed.phoneNumber,
        avatarUrl: parsed.avatarUrl,
      );
    } on AppException catch (e) {
      throw _toFailure(e);
    }
  }

  @override
  Future<AppUser> uploadAvatar({
    required AppUser currentUser,
    required String filePath,
  }) async {
    try {
      final json = await api.postMultipart(
        ApiEndpoints.avatar,
        fields: const {},
        fileField: 'image',
        filePath: filePath,
        auth: true,
      );
      final url = json['avatar_url'] as String?;
      if (url == null || url.isEmpty) {
        throw const Failure(FailureType.unknown, AppStrings.errUnknown);
      }
      return currentUser.copyWith(avatarUrl: url);
    } on AppException catch (e) {
      throw _toFailure(e);
    }
  }

  Failure _toFailure(AppException e) {
    switch (e.code) {
      case AppException.networkCode:
        return Failure(FailureType.network, e.message, code: e.code);
      case 'unauthorized':
        return Failure(FailureType.unauthorized, e.message, code: e.code);
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
