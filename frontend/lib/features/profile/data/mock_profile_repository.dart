import 'package:rijiki/core/session/app_user.dart';
import 'package:rijiki/features/profile/domain/profile_repository.dart';

class MockProfileRepository implements ProfileRepository {
  static const Duration _latency = Duration(milliseconds: 700);

  @override
  Future<AppUser> saveCustomerProfile({
    required AppUser currentUser,
    required String fullName,
    required String phoneNumber,
    required String address,
    required double latitude,
    required double longitude,
  }) async {
    await Future<void>.delayed(_latency);
    return currentUser.copyWith(
      fullName: fullName,
      phoneNumber: phoneNumber,
      defaultAddress: address,
      defaultLat: latitude,
      defaultLng: longitude,
      profileCompleted: true,
    );
  }

  @override
  Future<AppUser> saveProfile({
    required AppUser currentUser,
    required String fullName,
    required String phoneNumber,
  }) async {
    await Future<void>.delayed(_latency);
    return currentUser.copyWith(fullName: fullName, phoneNumber: phoneNumber);
  }

  @override
  Future<AppUser> uploadAvatar({
    required AppUser currentUser,
    required String filePath,
  }) async {
    await Future<void>.delayed(_latency);
    // Mock: pakai path lokal sebagai "URL" supaya fotonya langsung tampil.
    return currentUser.copyWith(avatarUrl: filePath);
  }
}
