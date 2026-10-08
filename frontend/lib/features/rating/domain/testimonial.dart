import 'package:flutter/foundation.dart';

@immutable
class Testimonial {
  const Testimonial({
    required this.id,
    required this.customerName,
    required this.ratingValue,
    required this.createdAt,
    this.comment,
    this.photoUrl,
    this.serviceName,
  });

  final String id;
  final String customerName;
  final int ratingValue;
  final DateTime createdAt;
  final String? comment;
  final String? photoUrl;
  final String? serviceName;
}
