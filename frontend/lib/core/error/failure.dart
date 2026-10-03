import 'package:rijiki/core/constants/app_strings.dart';

enum FailureType {
  network,
  validation,
  unauthorized,
  emailNotVerified,
  invalidOtp,
  conflict,
  rateLimited,
  server,
  unknown,
}

class Failure implements Exception {
  const Failure(this.type, this.message, {this.code});

  final FailureType type;
  final String message;
  final String? code;

  static String messageOf(Object error) {
    return error is Failure ? error.message : AppStrings.errUnknown;
  }

  @override
  String toString() => 'Failure($type, $message)';
}
