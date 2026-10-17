import 'package:flutter/foundation.dart';

@immutable
class WorkerReview {
  const WorkerReview({
    required this.id,
    required this.customerName,
    required this.ratingValue,
    required this.createdAt,
    required this.orderNumber,
    this.comment,
    this.serviceName,
  });

  final String id;
  final String customerName;
  final int ratingValue;
  final DateTime createdAt;
  final String orderNumber;
  final String? comment;
  final String? serviceName;
}

@immutable
class RatingSummary {
  const RatingSummary({
    required this.count,
    required this.distribution,
    this.average,
  });

  factory RatingSummary.from(List<WorkerReview> reviews) {
    final distribution = {for (var star = 5; star >= 1; star--) star: 0};
    var total = 0;
    for (final review in reviews) {
      distribution[review.ratingValue] =
          (distribution[review.ratingValue] ?? 0) + 1;
      total += review.ratingValue;
    }
    return RatingSummary(
      count: reviews.length,
      distribution: distribution,
      average: reviews.isEmpty ? null : total / reviews.length,
    );
  }

  final int count;
  final Map<int, int> distribution;
  final double? average;
}
