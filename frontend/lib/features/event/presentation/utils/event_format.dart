import 'package:flutter/material.dart';
import 'package:rijiki/core/enums/event_type.dart';
import 'package:rijiki/core/theme/app_colors.dart';
import 'package:rijiki/core/utils/date_formatter.dart';

extension EventTypeCmsX on EventType {
  String get cmsLabel => switch (this) {
    EventType.promo => 'Promo',
    EventType.collaboration => 'Kolaborasi',
    EventType.announcement => 'Info',
  };

  Color get cmsColor => switch (this) {
    EventType.promo => AppColors.rijikiOrange,
    EventType.collaboration => AppColors.primaryDark,
    EventType.announcement => AppColors.onSurfaceVariant,
  };

  IconData get cmsIcon => switch (this) {
    EventType.promo => Icons.local_offer_outlined,
    EventType.collaboration => Icons.groups_outlined,
    EventType.announcement => Icons.campaign_outlined,
  };
}

String formatEventPeriod(DateTime? start, DateTime? end) {
  if (start != null && end != null) return DateFormatter.range(start, end);
  if (start != null) return 'Mulai ${DateFormatter.shortDate(start)}';
  if (end != null) return 'Sampai ${DateFormatter.shortDate(end)}';
  return 'Tanpa batas waktu';
}
