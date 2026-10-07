import 'package:rijiki/features/rating/domain/testimonial.dart';

abstract interface class RatingRepository {
  Future<List<Testimonial>> fetchFeaturedTestimonials();
}
