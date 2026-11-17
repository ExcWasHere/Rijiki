import 'package:rijiki/core/session/app_user.dart';
import 'package:rijiki/features/profile/domain/profile_history.dart';

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

  /// Sepatu yang pernah dicuci customer, diambil dari riwayat order.
  Future<MyShoePage> fetchMyShoes({required int page, required int limit});

  /// Rating yang pernah diberikan customer beserta rata-ratanya.
  Future<CustomerRatingPage> fetchMyRatings({
    required int page,
    required int limit,
  });

  /// Unggah foto profil baru ([filePath] = path file lokal) lewat
  /// `POST /api/media/avatar`. Mengembalikan user dengan `avatarUrl` terbaru.
  Future<AppUser> uploadAvatar({
    required AppUser currentUser,
    required String filePath,
  });
}
