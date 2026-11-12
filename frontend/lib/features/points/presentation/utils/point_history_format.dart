import 'package:flutter/material.dart';
import 'package:rijiki/core/theme/app_colors.dart';
import 'package:rijiki/core/utils/date_formatter.dart';
import 'package:rijiki/features/points/domain/point_ledger_entry.dart';

String formatPoints(int value) {
  final digits = value.abs().toString();
  final buffer = StringBuffer();
  for (var i = 0; i < digits.length; i++) {
    if (i > 0 && (digits.length - i) % 3 == 0) buffer.write('.');
    buffer.write(digits[i]);
  }
  return '${value < 0 ? '-' : ''}$buffer';
}

String formatSignedPoints(int value) {
  if (value > 0) return '+${formatPoints(value)}';
  return formatPoints(value);
}

extension PointLedgerTypeUi on PointLedgerType {
  String get label => switch (this) {
    PointLedgerType.earn => 'Poin masuk',
    PointLedgerType.redeem => 'Tukar poin',
    PointLedgerType.adjustment => 'Penyesuaian',
    PointLedgerType.expire => 'Kedaluwarsa',
  };

  IconData get icon => switch (this) {
    PointLedgerType.earn => Icons.add_circle_outline_rounded,
    PointLedgerType.redeem => Icons.redeem_rounded,
    PointLedgerType.adjustment => Icons.tune_rounded,
    PointLedgerType.expire => Icons.timer_off_outlined,
  };
}

extension PointLedgerEntryUi on PointLedgerEntry {
  bool get isIncoming => pointsAmount > 0;

  Color get color {
    if (type == PointLedgerType.redeem) return AppColors.rijikiOrange;
    if (type == PointLedgerType.expire) return AppColors.onSurfaceVariant;
    return pointsAmount >= 0 ? AppColors.success : AppColors.error;
  }

  String get title {
    final text = description?.trim() ?? '';
    return text.isEmpty ? type.label : text;
  }

  String get subtitle {
    final order = orderNumber?.trim() ?? '';
    return order.isEmpty ? type.label : '${type.label} · Order $order';
  }

  String get dateLabel => DateFormatter.dateTime(createdAt.toLocal());
}
