abstract final class RupiahFormatter {
  static String full(num value) {
    final negative = value < 0;
    final digits = value.abs().round().toString();
    final buffer = StringBuffer();
    for (var i = 0; i < digits.length; i++) {
      if (i > 0 && (digits.length - i) % 3 == 0) buffer.write('.');
      buffer.write(digits[i]);
    }
    return '${negative ? '-' : ''}Rp $buffer';
  }

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
