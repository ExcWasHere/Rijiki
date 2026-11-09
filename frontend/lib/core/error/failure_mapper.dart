import 'package:rijiki/core/constants/app_strings.dart';
import 'package:rijiki/core/error/app_exception.dart';
import 'package:rijiki/core/error/failure.dart';

/// Mengubah galat jaringan/API menjadi [Failure] yang pesannya siap ditampilkan.
Failure failureFromException(AppException e) {
  switch (e.code) {
    case AppException.networkCode:
    case AppException.offlineCode:
    case AppException.timeoutCode:
      return Failure(FailureType.network, e.message, code: e.code);
    case 'unauthorized':
      return Failure(FailureType.unauthorized, e.message, code: e.code);
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
