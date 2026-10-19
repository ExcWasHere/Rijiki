import 'package:rijiki/features/worker_management/domain/kpi.dart';

const List<String> _monthNames = [
  'Januari',
  'Februari',
  'Maret',
  'April',
  'Mei',
  'Juni',
  'Juli',
  'Agustus',
  'September',
  'Oktober',
  'November',
  'Desember',
];

String formatPeriod(KpiPeriod period) =>
    '${_monthNames[period.month - 1]} ${period.year}';

String initialsOf(String name) {
  final words = name.trim().split(RegExp(r'\s+')).where((w) => w.isNotEmpty);
  if (words.isEmpty) return '?';
  if (words.length == 1) return words.first[0].toUpperCase();
  return '${words.first[0]}${words.last[0]}'.toUpperCase();
}

String formatTenure(DateTime joinDate, {DateTime? now}) {
  final today = now ?? DateTime.now();
  var months = (today.year - joinDate.year) * 12 + today.month - joinDate.month;
  if (today.day < joinDate.day) months--;
  if (months < 1) return 'Baru bergabung';
  final years = months ~/ 12;
  final rest = months % 12;
  if (years == 0) return '$rest bulan';
  if (rest == 0) return '$years tahun';
  return '$years tahun $rest bulan';
}

enum ScoreBand {
  excellent('Sangat baik', 85),
  good('Baik', 70),
  fair('Cukup', 55),
  poor('Perlu perbaikan', 0);

  const ScoreBand(this.label, this.min);

  final String label;
  final double min;

  static ScoreBand of(double score) =>
      ScoreBand.values.firstWhere((band) => score >= band.min);
}

String formatScore(double? score) =>
    score == null ? '-' : score.toStringAsFixed(0);

String formatRating(double? rating) =>
    rating == null ? '-' : rating.toStringAsFixed(1).replaceAll('.', ',');
