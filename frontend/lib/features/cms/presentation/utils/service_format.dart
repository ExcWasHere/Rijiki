enum DurationUnit {
  minute(1, 'Menit'),
  hour(60, 'Jam'),
  day(1440, 'Hari');

  const DurationUnit(this.minutes, this.label);

  final int minutes;
  final String label;
}

String formatDuration(int minutes) {
  if (minutes % 1440 == 0) return '${minutes ~/ 1440} hari';
  if (minutes % 60 == 0) return '${minutes ~/ 60} jam';
  return '$minutes menit';
}

({int value, DurationUnit unit}) splitDuration(int minutes) {
  if (minutes % 1440 == 0) return (value: minutes ~/ 1440, unit: DurationUnit.day);
  if (minutes % 60 == 0) return (value: minutes ~/ 60, unit: DurationUnit.hour);
  return (value: minutes, unit: DurationUnit.minute);
}
