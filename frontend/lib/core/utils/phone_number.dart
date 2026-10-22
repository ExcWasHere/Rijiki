abstract final class PhoneNumber {
  static final RegExp _valid = RegExp(r'^628\d{8,11}$');

  static String normalize(String raw) {
    final digits = raw.replaceAll(RegExp(r'\D'), '');
    if (digits.startsWith('62')) return digits;
    if (digits.startsWith('0')) return '62${digits.substring(1)}';
    if (digits.startsWith('8')) return '62$digits';
    return digits;
  }

  static bool isValid(String raw) => _valid.hasMatch(normalize(raw));
}
