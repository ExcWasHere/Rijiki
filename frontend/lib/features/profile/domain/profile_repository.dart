import 'package:rijiki/core/session/app_user.dart';

abstract interface class ProfileRepository {
  Future<AppUser> saveCustomerProfile({
    required AppUser currentUser,
    required String fullName,
    required String phoneNumber,
    required String address,
    required double latitude,
    required double longitude,
  });
}
