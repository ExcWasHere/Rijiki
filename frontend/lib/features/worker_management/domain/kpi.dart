import 'package:flutter/foundation.dart';

@immutable
class KpiPeriod {
  const KpiPeriod(this.month, this.year);

  factory KpiPeriod.current() {
    final now = DateTime.now();
    return KpiPeriod(now.month, now.year);
  }

  final int month;
  final int year;

  bool get isCurrent => this == KpiPeriod.current();

  KpiPeriod get previous =>
      month == 1 ? KpiPeriod(12, year - 1) : KpiPeriod(month - 1, year);

  KpiPeriod get next =>
      month == 12 ? KpiPeriod(1, year + 1) : KpiPeriod(month + 1, year);

  @override
  bool operator ==(Object other) =>
      other is KpiPeriod && other.month == month && other.year == year;

  @override
  int get hashCode => Object.hash(month, year);
}

enum KpiAspect {
  quality('Kualitas hasil kerja', 'Kebersihan dan ketelitian hasil pengerjaan.'),
  timeliness('Ketepatan waktu', 'Order selesai sesuai estimasi.'),
  neatness('Kerapian dan kebersihan', 'Area kerja, alat, dan penampilan.'),
  attitude('Sikap dan kerja sama', 'Komunikasi, disiplin, dan kerja tim.');

  const KpiAspect(this.label, this.description);

  final String label;
  final String description;
}

@immutable
class KpiAssessment {
  const KpiAssessment({
    required this.scores,
    required this.updatedAt,
    this.note,
  });

  final Map<KpiAspect, int> scores;
  final DateTime updatedAt;
  final String? note;

  double get operationalScore {
    final total = scores.values.fold<int>(0, (sum, v) => sum + v);
    return total / (KpiAspect.values.length * 5) * 100;
  }
}

@immutable
class WorkerKpi {
  const WorkerKpi({
    required this.workerId,
    required this.period,
    required this.totalOrdersHandled,
    this.avgRating,
    this.onTimeCompletionPct,
    this.assessment,
  });

  final String workerId;
  final KpiPeriod period;
  final int totalOrdersHandled;
  final double? avgRating;
  final double? onTimeCompletionPct;
  final KpiAssessment? assessment;

  double? get operationalScore => assessment?.operationalScore;

  double? get compositeScore {
    final operational = operationalScore;
    if (operational == null) return null;
    final rating = avgRating;
    if (rating == null) return operational;
    return 0.6 * operational + 0.4 * (rating / 5 * 100);
  }
}
