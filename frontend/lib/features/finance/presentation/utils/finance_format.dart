import 'package:rijiki/core/utils/date_formatter.dart';

String formatPercentSigned(double value) {
  final text = value.abs().toStringAsFixed(1).replaceAll('.', ',');
  return '${value >= 0 ? '+' : '-'}$text%';
}

/// Delegasi ke [DateFormatter] supaya tabel bulan tidak diduplikasi.
String formatDate(DateTime date) => DateFormatter.shortDate(date);

String formatDateGroup(DateTime date, {DateTime? now}) =>
    DateFormatter.groupLabel(date, now: now);

String formatDateRange(DateTime start, DateTime end) =>
    DateFormatter.range(start, end);

String formatQuantity(double quantity, String? unit) {
  final text = quantity == quantity.roundToDouble()
      ? quantity.toInt().toString()
      : quantity.toString().replaceAll('.', ',');
  return unit == null || unit.isEmpty ? text : '$text $unit';
}
