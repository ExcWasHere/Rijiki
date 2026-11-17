import 'package:rijiki/core/session/app_user.dart';

abstract interface class AuthRepository {
  Future<AppUser?> restoreSession();

  Future<AppUser> login({required String email, required String password});

  Future<AppUser?> loginWithGoogle();

  Future<void> register({required String email, required String password});

  Future<AppUser> verifyEmail({required String email, required String code});

  Future<void> resendVerification({required String email});

  Future<void> logout();

    Future<void> changePassword({
    required String currentPassword,
    required String newPassword,
  });

  /// Mengirim permintaan ganti email. `true` = masih perlu kode OTP ke email
  /// baru; `false` = email sudah langsung berganti (konfirmasi email dimatikan
  /// di Supabase Auth).
  Future<bool> requestEmailChange({
    required String newEmail,
    required String password,
  });

  Future<void> confirmEmailChange({
    required String newEmail,
    required String code,
  });
}
