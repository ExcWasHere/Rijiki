import 'package:flutter/foundation.dart';
import 'package:rijiki/core/enums/event_type.dart';

@immutable
class PromoEventInput {
  const PromoEventInput({
    required this.title,
    required this.type,
    this.description,

    /// Path berkas lokal (baru dipilih) atau URL http (banner lama). Berkas
    /// lokal diunggah ke R2 oleh repository sebelum event disimpan.
    this.bannerImageUrl,
    this.startDate,
    this.endDate,
    this.isPublished = true,
    this.relatedPromoId,
  });

  final String title;
  final EventType type;
  final String? description;
  final String? bannerImageUrl;
  final DateTime? startDate;
  final DateTime? endDate;
  final bool isPublished;
  final String? relatedPromoId;
}
