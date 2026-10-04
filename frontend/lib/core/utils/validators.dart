import 'package:rijiki/core/constants/app_constants.dart';
import 'package:rijiki/core/constants/app_strings.dart';

abstract final class Validators {
  static final RegExp _emailPattern = RegExp(r'^[^\s@]+@[^\s@]+\.[^\s@]+$');

  static String? email(String? value) {
    final text = value?.trim() ?? '';
    if (text.isEmpty) return AppStrings.errEmailRequired;
    if (!_emailPattern.hasMatch(text)) return AppStrings.errEmailInvalid;
    return null;
  }

  static String? passwordRequired(String? value) {
    if (value == null || value.isEmpty) return AppStrings.errPasswordRequired;
    return null;
  }

  static String? newPassword(String? value) {
    if (value == null || value.isEmpty) return AppStrings.errPasswordRequired;
    if (value.length < AppConstants.passwordMinLength) {
      return AppStrings.errPasswordMin;
    }
    return null;
  }

  static String? confirmPassword(String? value, String original) {
    if (value == null || value.isEmpty) return AppStrings.errConfirmRequired;
    if (value != original) return AppStrings.errConfirmMismatch;
    return null;
  }
}
