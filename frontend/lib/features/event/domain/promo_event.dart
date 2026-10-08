import 'package:flutter/foundation.dart';
import 'package:rijiki/core/enums/event_type.dart';

@immutable
class PromoEvent {
  const PromoEvent({
    required this.id,
    required this.title,
    required this.type,
    this.description,
    this.bannerImageUrl,
    this.startDate,
    this.endDate,
  });

  final String id;
  final String title;
  final EventType type;
  final String? description;
  final String? bannerImageUrl;
  final DateTime? startDate;
  final DateTime? endDate;

  factory PromoEvent.fromJson(Map<String, dynamic> json) {
    DateTime? parseDate(Object? raw) =>
        raw == null ? null : DateTime.parse(raw as String);

    return PromoEvent(
      id: json['id'] as String,
      title: json['title'] as String,
      type: EventType.fromJson(json['event_type'] as String),
      description: json['description'] as String?,
      bannerImageUrl: json['banner_image_url'] as String?,
      startDate: parseDate(json['start_date']),
      endDate: parseDate(json['end_date']),
    );
  }
}
