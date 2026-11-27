import 'dart:typed_data';

import 'package:flutter/foundation.dart';

enum RatingListFilter { all, featured, withPhoto }

/// Rating untuk staf (owner atau pemegang izin manage_testimonials).
@immutable
class ManagedRating {
  const ManagedRating({
    required this.id,
    required this.orderId,
    required this.ratingValue,
    required this.createdAt,
    this.orderNumber,
    this.customerName,
    this.workerName,
    this.serviceNames = const [],
    this.comment,
    this.photoKey,
    this.isFeatured = false,
  });

  final String id;
  final String orderId;
  final String? orderNumber;
  final String? customerName;
  final String? workerName;
  final List<String> serviceNames;
  final int ratingValue;
  final String? comment;

  /// Key objek di bucket privat; dimuat lewat PrivateImage.
  final String? photoKey;
  final bool isFeatured;
  final DateTime createdAt;

  factory ManagedRating.fromJson(Map<String, dynamic> json) {
    return ManagedRating(
      id: json['id'] as String,
      orderId: json['order_id'] as String,
      orderNumber: json['order_number'] as String?,
      customerName: json['customer_name'] as String?,
      workerName: json['worker_name'] as String?,
      serviceNames: [
        for (final name in (json['service_names'] as List<dynamic>? ?? const []))
          name as String,
      ],
      ratingValue: (json['rating_value'] as num).toInt(),
      comment: json['comment'] as String?,
      photoKey: json['photo_key'] as String?,
      isFeatured: json['is_featured'] as bool? ?? false,
      createdAt: DateTime.parse(json['created_at'] as String).toLocal(),
    );
  }

  ManagedRating copyWith({bool? isFeatured}) {
    return ManagedRating(
      id: id,
      orderId: orderId,
      orderNumber: orderNumber,
      customerName: customerName,
      workerName: workerName,
      serviceNames: serviceNames,
      ratingValue: ratingValue,
      comment: comment,
      photoKey: photoKey,
      isFeatured: isFeatured ?? this.isFeatured,
      createdAt: createdAt,
    );
  }
}

@immutable
class RatingSummary {
  const RatingSummary({
    required this.total,
    required this.featured,
    this.average,
  });

  final int total;
  final int featured;
  final double? average;

  factory RatingSummary.fromJson(Map<String, dynamic> json) {
    return RatingSummary(
      total: (json['total'] as num?)?.toInt() ?? 0,
      featured: (json['featured'] as num?)?.toInt() ?? 0,
      average: (json['average'] as num?)?.toDouble(),
    );
  }
}

@immutable
class ManagedRatingPage {
  const ManagedRatingPage({
    required this.items,
    required this.total,
    required this.page,
    required this.summary,
  });

  final List<ManagedRating> items;
  final int total;
  final int page;
  final RatingSummary summary;
}

enum RecapSource {
  testimonials('testimonials'),
  beforeAfter('before_after');

  const RecapSource(this.value);

  final String value;
}

@immutable
class RecapRequest {
  const RecapRequest({required this.source, this.startDate, this.endDate});

  final RecapSource source;
  final DateTime? startDate;
  final DateTime? endDate;

  static String _date(DateTime d) {
    final month = d.month.toString().padLeft(2, '0');
    final day = d.day.toString().padLeft(2, '0');
    return '${d.year.toString().padLeft(4, '0')}-$month-$day';
  }

  Map<String, String> toQuery() => {
    'source': source.value,
    if (startDate != null) 'start_date': _date(startDate!),
    if (endDate != null) 'end_date': _date(endDate!),
  };
}

@immutable
class RecapFile {
  const RecapFile({
    required this.bytes,
    required this.fileName,
    required this.total,
    required this.included,
    required this.truncated,
  });

  final Uint8List bytes;
  final String fileName;

  /// Foto yang seharusnya masuk rekap.
  final int total;

  /// Foto yang benar-benar dimasukkan (ada batas per rekap).
  final int included;
  final bool truncated;
}
