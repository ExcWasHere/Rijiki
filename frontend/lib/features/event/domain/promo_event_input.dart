import 'package:flutter/foundation.dart';
import 'package:rijiki/core/enums/event_type.dart';

@immutable
class PromoEventInput {
  const PromoEventInput({
    required this.title,
    required this.type,
    this.description,
    this.bannerImageUrl,
    this.startDate,
    this.endDate,
    this.isPublished = true,
  });

  final String title;
  final EventType type;
  final String? description;
  final String? bannerImageUrl;
  final DateTime? startDate;
  final DateTime? endDate;
  final bool isPublished;
}
