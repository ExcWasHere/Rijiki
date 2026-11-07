import 'package:flutter/foundation.dart';
import 'package:rijiki/features/rating/domain/testimonial.dart';

@immutable
class RatingSubmission {
  const RatingSubmission({this.pointsAwarded = 0, this.alreadyRated = false});

  /// Poin yang baru diberikan karena rating ini (0 bila aturan poin nonaktif).
  final int pointsAwarded;

  /// Order ini ternyata sudah pernah diberi rating (mis. kirim ulang setelah sinyal putus).
  final bool alreadyRated;
}

abstract interface class RatingRepository {
  /// Testimoni pilihan untuk home customer.
  Future<List<Testimonial>> fetchFeaturedTestimonials();

  /// Customer memberi rating untuk order yang sudah selesai. [photoPath] opsional.
  Future<RatingSubmission> submitRating({
    required String orderId,
    required int ratingValue,
    String? comment,
    String? photoPath,
  });
}
