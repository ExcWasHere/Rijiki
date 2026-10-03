import 'package:rijiki/core/constants/app_strings.dart';
import 'package:rijiki/core/enums/user_role.dart';
import 'package:rijiki/core/error/failure.dart';
import 'package:rijiki/core/session/app_user.dart';
import 'package:rijiki/features/auth/domain/auth_repo.dart';

class _MockAccount {
  _MockAccount({
    required this.password,
    required this.user,
    this.verified = true,
  });

  final String password;
  final AppUser user;
  bool verified;
}

class MockAuthRepository implements AuthRepository {
  static const String validOtp = '123456';
  static const Duration _latency = Duration(milliseconds: 700);

  final Map<String, _MockAccount> _accounts = {
    'customer@rijiki.id': _MockAccount(
      password: 'password123',
      user: const AppUser(
        id: 'mock-customer',
        email: 'customer@rijiki.id',
        role: UserRole.customer,
        fullName: 'Budi Santoso',
        profileCompleted: true,
      ),
    ),
    'baru@rijiki.id': _MockAccount(
      password: 'password123',
      user: const AppUser(
        id: 'mock-baru',
        email: 'baru@rijiki.id',
        role: UserRole.customer,
        profileCompleted: false,
      ),
    ),
    'belum@rijiki.id': _MockAccount(
      password: 'password123',
      verified: false,
      user: const AppUser(
        id: 'mock-belum',
        email: 'belum@rijiki.id',
        role: UserRole.customer,
        profileCompleted: false,
      ),
    ),
    'worker@rijiki.id': _MockAccount(
      password: 'password123',
      user: const AppUser(
        id: 'mock-worker',
        email: 'worker@rijiki.id',
        role: UserRole.worker,
        fullName: 'Siti Worker',
        profileCompleted: true,
      ),
    ),
    'owner@rijiki.id': _MockAccount(
      password: 'password123',
      user: const AppUser(
        id: 'mock-owner',
        email: 'owner@rijiki.id',
        role: UserRole.owner,
        fullName: 'Owner Rijiki',
        profileCompleted: true,
        ownerBypass: true,
      ),
    ),
  };

  @override
  Future<AppUser?> restoreSession() async {
    await Future<void>.delayed(const Duration(milliseconds: 200));
    return null;
  }

  @override
  Future<AppUser> login({required String email, required String password}) async {
    await Future<void>.delayed(_latency);
    final account = _accounts[email.trim().toLowerCase()];
    if (account == null || account.password != password) {
      throw const Failure(
        FailureType.unauthorized,
        AppStrings.errInvalidCredentials,
      );
    }
    if (!account.verified) {
      throw const Failure(
        FailureType.emailNotVerified,
        'Email belum diverifikasi',
      );
    }
    return account.user;
  }

  @override
  Future<void> register({required String email, required String password}) async {
    await Future<void>.delayed(_latency);
    final key = email.trim().toLowerCase();
    final existing = _accounts[key];
    if (existing != null && existing.verified) {
      throw const Failure(FailureType.conflict, AppStrings.errEmailTaken);
    }
    _accounts[key] = _MockAccount(
      password: password,
      verified: false,
      user: AppUser(
        id: 'mock-${_accounts.length}',
        email: key,
        role: UserRole.customer,
        profileCompleted: false,
      ),
    );
  }

  @override
  Future<AppUser> verifyEmail({required String email, required String code}) async {
    await Future<void>.delayed(_latency);
    final account = _accounts[email.trim().toLowerCase()];
    if (account == null || code != validOtp) {
      throw const Failure(FailureType.invalidOtp, AppStrings.errInvalidOtp);
    }
    account.verified = true;
    return account.user;
  }

  @override
  Future<void> resendVerification({required String email}) async {
    await Future<void>.delayed(_latency);
  }

  @override
  Future<void> logout() async {}
}
