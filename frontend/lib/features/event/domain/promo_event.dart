import 'package:flutter/foundation.dart';
import 'package:rijiki/core/enums/event_type.dart';
import 'package:rijiki/features/event/domain/event_promo.dart';

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
    this.isPublished = true,
    this.relatedPromoId,
    this.promo,
  });

  final String id;
  final String title;
  final EventType type;
  final String? description;
  final String? bannerImageUrl;
  final DateTime? startDate;
  final DateTime? endDate;
  final bool isPublished;

  /// Promo yang terhubung (events.related_promo_id), bila ada.
  final String? relatedPromoId;

  /// Ringkasan promo dari backend; null bila tidak terhubung.
  final EventPromo? promo;

  factory PromoEvent.fromJson(Map<String, dynamic> json) {
    DateTime? parseDate(Object? raw) =>
        raw == null ? null : DateTime.parse(raw as String);

    final promoJson = json['promo'];

    return PromoEvent(
      id: json['id'] as String,
      title: json['title'] as String,
      type: EventType.fromJson(json['event_type'] as String),
      description: json['description'] as String?,
      bannerImageUrl: json['banner_image_url'] as String?,
      startDate: parseDate(json['start_date']),
      endDate: parseDate(json['end_date']),
      isPublished: json['is_published'] as bool? ?? true,
      relatedPromoId: json['related_promo_id'] as String?,
      promo: promoJson is Map<String, dynamic>
          ? EventPromo.fromJson(promoJson)
          : null,
    );
  }

  PromoEvent copyWith({bool? isPublished}) {
    return PromoEvent(
      id: id,
      title: title,
      type: type,
      description: description,
      bannerImageUrl: bannerImageUrl,
      startDate: startDate,
      endDate: endDate,
      isPublished: isPublished ?? this.isPublished,
      relatedPromoId: relatedPromoId,
      promo: promo,
    );
  }
}
