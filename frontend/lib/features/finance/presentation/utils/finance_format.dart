const List<String> _months = [
  'Jan',
  'Feb',
  'Mar',
  'Apr',
  'Mei',
  'Jun',
  'Jul',
  'Agu',
  'Sep',
  'Okt',
  'Nov',
  'Des',
];

String formatPercentSigned(double value) {
  final text = value.abs().toStringAsFixed(1).replaceAll('.', ',');
  return '${value >= 0 ? '+' : '-'}$text%';
}

String formatDate(DateTime date) {
  return '${date.day} ${_months[date.month - 1]} ${date.year}';
}

String formatDateGroup(DateTime date, {DateTime? now}) {
  final today = _dateOnly(now ?? DateTime.now());
  final day = _dateOnly(date);
  final diff = today.difference(day).inDays;
  if (diff == 0) return 'Hari ini';
  if (diff == 1) return 'Kemarin';
  return formatDate(day);
}

String formatDateRange(DateTime start, DateTime end) {
  if (start.year == end.year) {
    return '${start.day} ${_months[start.month - 1]} - ${formatDate(end)}';
  }
  return '${formatDate(start)} - ${formatDate(end)}';
}

String formatQuantity(double quantity, String? unit) {
  final text = quantity == quantity.roundToDouble()
      ? quantity.toInt().toString()
      : quantity.toString().replaceAll('.', ',');
  return unit == null || unit.isEmpty ? text : '$text $unit';
}

DateTime _dateOnly(DateTime date) => DateTime(date.year, date.month, date.day);
