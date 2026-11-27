import 'package:rijiki/features/rating/domain/managed_rating.dart';

abstract interface class TestimonialManageRepository {
  Future<ManagedRatingPage> fetchRatings(
    RatingListFilter filter, {
    int page = 1,
    int limit = 20,
  });

  /// Menandai atau mencabut testimoni pilihan (tampil di home customer).
  Future<ManagedRating> setFeatured(String id, bool isFeatured);

  /// Mengunduh rekap ZIP (foto + ringkasan.csv).
  Future<RecapFile> downloadRecap(RecapRequest request);
}
