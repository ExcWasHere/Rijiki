import 'package:rijiki/core/constants/app_strings.dart';
import 'package:rijiki/core/error/app_exception.dart';
import 'package:rijiki/core/error/failure.dart';
import 'package:rijiki/core/network/api_client.dart';
import 'package:rijiki/core/network/api_endpoint.dart';
import 'package:rijiki/features/rating/domain/managed_rating.dart';
import 'package:rijiki/features/rating/domain/testimonial_manage_repository.dart';

class TestimonialManageRepositoryImpl implements TestimonialManageRepository {
  TestimonialManageRepositoryImpl({required this.api});

  final ApiClient api;

  @override
  Future<ManagedRatingPage> fetchRatings(
    RatingListFilter filter, {
    int page = 1,
    int limit = 20,
  }) async {
    final query = {
      'page': '$page',
      'limit': '$limit',
      if (filter == RatingListFilter.featured) 'featured': 'true',
      if (filter == RatingListFilter.withPhoto) 'has_photo': 'true',
    };
    try {
      final path = Uri(
        path: ApiEndpoints.managementTestimonials,
        queryParameters: query,
      ).toString();
      final json = await api.get(path, auth: true);
      final raw = json['items'] as List<dynamic>? ?? const [];
      return ManagedRatingPage(
        items: [
          for (final item in raw)
            ManagedRating.fromJson(item as Map<String, dynamic>),
        ],
        total: (json['total'] as num?)?.toInt() ?? 0,
        page: (json['page'] as num?)?.toInt() ?? page,
        summary: RatingSummary.fromJson(
          json['summary'] as Map<String, dynamic>? ?? const {},
        ),
      );
    } on AppException catch (e) {
      throw _toFailure(e);
    }
  }

  @override
  Future<ManagedRating> setFeatured(String id, bool isFeatured) async {
    try {
      final json = await api.patch(
        ApiEndpoints.managementTestimonialFeatured(id),
        auth: true,
        body: {'is_featured': isFeatured},
      );
      return ManagedRating.fromJson(json);
    } on AppException catch (e) {
      throw _toFailure(e);
    }
  }

  @override
  Future<RecapFile> downloadRecap(RecapRequest request) async {
    try {
      final path = Uri(
        path: ApiEndpoints.managementTestimonialsExport,
        queryParameters: request.toQuery(),
      ).toString();
      final file = await api.getFile(path, auth: true);
      final headers = file.headers;
      return RecapFile(
        bytes: file.bytes,
        fileName:
            _fileNameFrom(headers['content-disposition']) ??
            'rekap-${request.source.value}.zip',
        total: int.tryParse(headers['x-export-total'] ?? '') ?? 0,
        included: int.tryParse(headers['x-export-included'] ?? '') ?? 0,
        truncated: headers['x-export-truncated'] == 'true',
      );
    } on AppException catch (e) {
      throw _toFailure(e);
    }
  }

  static String? _fileNameFrom(String? disposition) {
    if (disposition == null) return null;
    final match = RegExp(r'filename="?([^";]+)"?').firstMatch(disposition);
    return match?.group(1);
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
        return Failure(FailureType.validation, e.message, code: e.code);
      case 'photo_missing':
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
