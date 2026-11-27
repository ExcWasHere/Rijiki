import 'package:flutter/foundation.dart';

/// Pilihan promo untuk dropdown di form event (owner / worker berizin).
@immutable
class PromoOption {
  const PromoOption({
    required this.id,
    required this.code,
    required this.title,
    required this.isActive,
    required this.startDate,
    required this.endDate,
  });

  final String id;
  final String code;
  final String title;
  final bool isActive;
  final DateTime startDate;
  final DateTime endDate;

  String get label => '$code · $title';

  /// Keterangan bila promo sedang tidak bisa dipakai customer; null bila normal.
  String? get statusNote {
    if (!isActive) return 'nonaktif';
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    if (today.isBefore(startDate)) return 'belum mulai';
    if (today.isAfter(endDate)) return 'sudah berakhir';
    return null;
  }

  factory PromoOption.fromJson(Map<String, dynamic> json) {
    return PromoOption(
      id: json['id'] as String,
      code: json['code'] as String,
      title: json['title'] as String,
      isActive: json['is_active'] as bool? ?? true,
      startDate: DateTime.parse(json['start_date'] as String),
      endDate: DateTime.parse(json['end_date'] as String),
    );
  }
}
