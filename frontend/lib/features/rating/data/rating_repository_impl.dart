import 'package:rijiki/core/constants/app_strings.dart';
import 'package:rijiki/core/error/app_exception.dart';
import 'package:rijiki/core/error/failure.dart';
import 'package:rijiki/core/network/api_client.dart';
import 'package:rijiki/core/network/api_endpoint.dart';
import 'package:rijiki/features/rating/domain/rating_repository.dart';
import 'package:rijiki/features/rating/domain/testimonial.dart';

class RatingRepositoryImpl implements RatingRepository {
  RatingRepositoryImpl({required this.api});

  final ApiClient api;

  @override
  Future<List<Testimonial>> fetchFeaturedTestimonials() async {
    try {
      final json = await api.get(ApiEndpoints.testimonialsFeatured, auth: true);
      final raw = json['items'] as List<dynamic>? ?? const [];
      return [
        for (final item in raw)
          _testimonialFromJson(item as Map<String, dynamic>),
      ];
    } on AppException catch (e) {
      throw _toFailure(e);
    }
  }

  @override
  Future<RatingSubmission> submitRating({
    required String orderId,
    required int ratingValue,
    String? comment,
    String? photoPath,
  }) async {
    final text = comment?.trim() ?? '';
    try {
      final json = await api.postMultipart(
        ApiEndpoints.orderRating(orderId),
        auth: true,
        fields: {
          'rating_value': '$ratingValue',
          if (text.isNotEmpty) 'comment': text,
        },
        fileField: photoPath == null ? null : 'photo',
        filePath: photoPath,
      );
      return RatingSubmission(
        pointsAwarded: (json['points_awarded'] as num?)?.toInt() ?? 0,
      );
    } on AppException catch (e) {
      throw _toFailure(e);
    }
  }

  static Testimonial _testimonialFromJson(Map<String, dynamic> json) {
    return Testimonial(
      id: json['id'] as String,
      customerName: json['customer_name'] as String? ?? 'Pelanggan Rijiki',
      ratingValue: (json['rating_value'] as num).toInt(),
      createdAt: DateTime.parse(json['created_at'] as String).toLocal(),
      comment: json['comment'] as String?,
      photoUrl: json['photo_url'] as String?,
      serviceName: json['service_name'] as String?,
    );
  }

  Failure _toFailure(AppException e) {
    switch (e.code) {
      case AppException.networkCode:
      case AppException.offlineCode:
      case AppException.timeoutCode:
        return Failure(FailureType.network, e.message, code: e.code);
      case 'unauthorized':
        return Failure(FailureType.unauthorized, e.message, code: e.code);
      case 'validation_error':
      case 'unsupported_media_type':
      case 'file_too_large':
        return Failure(FailureType.validation, e.message, code: e.code);
      case 'already_rated':
      case 'order_not_completed':
        return Failure(FailureType.conflict, e.message, code: e.code);
    }
    if ((e.statusCode ?? 0) >= 500) {
      return Failure(FailureType.server, e.message, code: e.code);
    }
    return Failure(
      FailureType.unknown,
      e.message.isEmpty ? AppStrings.errUnknown : e.message,
      code: e.code,
    );
  }
}
