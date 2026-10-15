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

String formatDate(DateTime date) {
  return '${date.day} ${_months[date.month - 1]} ${date.year}';
}

String formatDateRange(DateTime start, DateTime end) {
  if (start.year == end.year) {
    return '${start.day} ${_months[start.month - 1]} - ${formatDate(end)}';
  }
  return '${formatDate(start)} - ${formatDate(end)}';
}
