import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:rijiki/app/providers.dart';
import 'package:rijiki/core/error/failure.dart';
import 'package:rijiki/features/rating/domain/rating_repository.dart';

@immutable
class RatingSubmitState {
  const RatingSubmitState({
    this.rating = 0,
    this.photoPath,
    this.isSubmitting = false,
    this.error,
  });

  final int rating;
  final String? photoPath;
  final bool isSubmitting;
  final String? error;

  bool get canSubmit => rating >= 1 && !isSubmitting;

  RatingSubmitState copyWith({
    int? rating,
    String? photoPath,
    bool clearPhoto = false,
    bool? isSubmitting,
    String? error,
    bool clearError = false,
  }) {
    return RatingSubmitState(
      rating: rating ?? this.rating,
      photoPath: clearPhoto ? null : (photoPath ?? this.photoPath),
      isSubmitting: isSubmitting ?? this.isSubmitting,
      error: clearError ? null : (error ?? this.error),
    );
  }
}

class RatingSubmitController extends Notifier<RatingSubmitState> {
  @override
  RatingSubmitState build() => const RatingSubmitState();

  void setRating(int value) =>
      state = state.copyWith(rating: value.clamp(1, 5).toInt());

  void setPhoto(String path) => state = state.copyWith(photoPath: path);

  void clearPhoto() => state = state.copyWith(clearPhoto: true);

  /// Mengembalikan hasil bila rating tercatat (termasuk "sudah pernah diberi
  /// rating", mis. kirim ulang setelah sinyal putus), atau null bila gagal.
  Future<RatingSubmission?> submit({
    required String orderId,
    String? comment,
  }) async {
    if (!state.canSubmit) return null;
    state = state.copyWith(isSubmitting: true, clearError: true);
    try {
      final result = await ref
          .read(ratingRepositoryProvider)
          .submitRating(
            orderId: orderId,
            ratingValue: state.rating,
            comment: comment,
            photoPath: state.photoPath,
          );
      if (!ref.mounted) return result;
      state = state.copyWith(isSubmitting: false);
      return result;
    } catch (e) {
      if (!ref.mounted) return null;
      if (e is Failure && e.code == 'already_rated') {
        state = state.copyWith(isSubmitting: false);
        return const RatingSubmission(alreadyRated: true);
      }
      state = state.copyWith(
        isSubmitting: false,
        error: e is Failure && e.message.trim().isNotEmpty
            ? e.message
            : 'Rating gagal dikirim. Coba lagi ya.',
      );
      return null;
    }
  }
}

final ratingSubmitProvider =
    NotifierProvider.autoDispose<RatingSubmitController, RatingSubmitState>(
      RatingSubmitController.new,
    );
