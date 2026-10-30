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

  /// Simpan nama dan nomor HP untuk owner/worker (tanpa alamat default).
  Future<AppUser> saveProfile({
    required AppUser currentUser,
    required String fullName,
    required String phoneNumber,
  });

  /// Unggah foto profil baru ([filePath] = path file lokal) lewat
  /// `POST /api/media/avatar`. Mengembalikan user dengan `avatarUrl` terbaru.
  Future<AppUser> uploadAvatar({
    required AppUser currentUser,
    required String filePath,
  });
}
