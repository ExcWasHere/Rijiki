abstract final class AppStrings {
  static const String appName = 'RIJIKI';
  static const String appTagline = 'Shoe & Bag Care';

  static const String collabPrimary = 'Rijiki';
  static const String collabSecondary = 'TaTuTI';

  static const String splashErrorTitle = 'Gagal memuat sesi';
  static const String retry = 'Coba lagi';

  // General Auth
  static const String emailLabel = 'Email';
  static const String emailHint = 'nama@email.com';
  static const String passwordLabel = 'Password';
  static const String passwordHint = 'Minimal 8 karakter';
  static const String confirmPasswordLabel = 'Konfirmasi password';
  static const String logout = 'Keluar';

  // Login
  static const String loginTitle = 'Masuk';
  static const String loginSubtitle =
      'Selamat datang kembali! Masuk untuk lanjut merawat sepatu kamu.';
  static const String loginButton = 'Masuk';
  static const String noAccountPrompt = 'Belum punya akun?';
  static const String registerLink = 'Daftar';

  // Register
  static const String registerTitle = 'Buat akun';
  static const String registerSubtitle =
      'Cukup email dan password. Data lain bisa kamu lengkapi setelah ini.';
  static const String registerButton = 'Daftar';
  static const String hasAccountPrompt = 'Sudah punya akun?';
  static const String loginLink = 'Masuk';

  // Verifikasi email
  static const String verifyTitle = 'Verifikasi email';
  static const String verifySubtitle = 'Masukkan 6 digit kode yang kami kirim ke';
  static const String verifyButton = 'Verifikasi';
  static const String resendButton = 'Kirim ulang kode';
  static const String changeEmail = 'Ganti email';
  static String resendCountdown(int seconds) => 'Kirim ulang kode dalam ${seconds}s';

  // Onboarding (placeholder)
  static const String onboardingPlaceholder =
      'Halaman onboarding belum dibuat.\nNama & nomor HP akan diisi di sini.';

  // Validasi form
  static const String errEmailRequired = 'Email wajib diisi';
  static const String errEmailInvalid = 'Format email tidak valid';
  static const String errPasswordRequired = 'Password wajib diisi';
  static const String errPasswordMin = 'Password minimal 8 karakter';
  static const String errConfirmRequired = 'Konfirmasi password wajib diisi';
  static const String errConfirmMismatch = 'Konfirmasi password tidak sama';

  // Error umum
  static const String errNetwork =
      'Tidak bisa terhubung ke server. Cek koneksi internet kamu.';
  static const String errUnknown = 'Terjadi kesalahan. Coba lagi.';
  static const String errSessionExpired = 'Sesi berakhir, silakan masuk lagi.';
  static const String errInvalidCredentials = 'Email atau password salah';
  static const String errInvalidOtp = 'Kode salah atau sudah kedaluwarsa';
  static const String errEmailTaken = 'Email sudah terdaftar. Silakan masuk';
}
