abstract final class RupiahFormatter {
  /// Angka dengan pemisah ribuan, tanpa awalan "Rp".
  /// Contoh: 1250000 → "1.250.000", -5000 → "-5.000".
  static String grouped(num value) {
    final negative = value < 0;
    final digits = value.abs().round().toString();
    final buffer = StringBuffer();
    for (var i = 0; i < digits.length; i++) {
      if (i > 0 && (digits.length - i) % 3 == 0) buffer.write('.');
      buffer.write(digits[i]);
    }
    return '${negative ? '-' : ''}$buffer';
  }

  /// Contoh: 25000 → "Rp 25.000".
  static String full(num value) => 'Rp ${grouped(value)}';

  /// Ringkas untuk grafik: 1.500.000 → "Rp 1,5 jt".
  static String compact(num value) {
    final negative = value < 0;
    final abs = value.abs().toDouble();
    final String body;
    if (abs >= 1e9) {
      body = '${_oneDecimal(abs / 1e9)} M';
    } else if (abs >= 1e6) {
      body = '${_oneDecimal(abs / 1e6)} jt';
    } else if (abs >= 1e3) {
      body = '${(abs / 1e3).round()} rb';
    } else {
      body = abs.round().toString();
    }
    return '${negative ? '-' : ''}Rp $body';
  }

  static String _oneDecimal(double value) {
    final fixed = value.toStringAsFixed(1);
    final trimmed = fixed.endsWith('.0')
        ? fixed.substring(0, fixed.length - 2)
        : fixed;
    return trimmed.replaceAll('.', ',');
  }
}
