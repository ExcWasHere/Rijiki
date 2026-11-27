abstract final class DateFormatter {
  static const List<String> _months = [
    'Jan', 'Feb', 'Mar', 'Apr', 'Mei', 'Jun',
    'Jul', 'Agu', 'Sep', 'Okt', 'Nov', 'Des',
  ];

  static String shortDate(DateTime date) =>
      '${date.day} ${_months[date.month - 1]} ${date.year}';

  static String time(DateTime date) =>
      '${date.hour.toString().padLeft(2, '0')}.${date.minute.toString().padLeft(2, '0')}';

  static String dateTime(DateTime date) => '${shortDate(date)}, ${time(date)}';

  /// Rentang tanggal; tahun yang sama hanya ditulis sekali di ujung.
  static String range(DateTime start, DateTime end) {
    if (start.year == end.year) {
      return '${start.day} ${_months[start.month - 1]} - ${shortDate(end)}';
    }
    return '${shortDate(start)} - ${shortDate(end)}';
  }

  /// "Hari ini" / "Kemarin" / tanggal, untuk pengelompokan daftar.
  static String groupLabel(DateTime date, {DateTime? now}) {
    final today = dateOnly(now ?? DateTime.now());
    final day = dateOnly(date);
    final diff = today.difference(day).inDays;
    if (diff == 0) return 'Hari ini';
    if (diff == 1) return 'Kemarin';
    return shortDate(day);
  }

  static DateTime dateOnly(DateTime date) =>
      DateTime(date.year, date.month, date.day);

  static String greeting(DateTime now) {
    final hour = now.hour;
    if (hour < 11) return 'Selamat pagi';
    if (hour < 15) return 'Selamat siang';
    if (hour < 18) return 'Selamat sore';
    return 'Selamat malam';
  }

  static String? validity(DateTime? start, DateTime? end) {
    if (end != null) return 'Sampai ${shortDate(end)}';
    if (start != null) return 'Mulai ${shortDate(start)}';
    return null;
  }
}
