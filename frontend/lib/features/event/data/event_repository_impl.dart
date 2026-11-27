import 'package:rijiki/core/constants/app_strings.dart';
import 'package:rijiki/core/error/app_exception.dart';
import 'package:rijiki/core/error/failure.dart';
import 'package:rijiki/core/error/failure_mapper.dart';
import 'package:rijiki/core/network/api_client.dart';
import 'package:rijiki/core/network/api_endpoint.dart';
import 'package:rijiki/features/event/domain/event_repository.dart';
import 'package:rijiki/features/event/domain/promo_event.dart';
import 'package:rijiki/features/event/domain/promo_event_input.dart';
import 'package:rijiki/features/event/domain/promo_option.dart';

class EventRepositoryImpl implements EventRepository {
  EventRepositoryImpl({required this.api});

  final ApiClient api;

  @override
  Future<List<PromoEvent>> fetchActiveEvents() => _list(ApiEndpoints.events);

  @override
  Future<List<PromoEvent>> fetchAllEvents() =>
      _list(ApiEndpoints.managementEvents);

  Future<List<PromoEvent>> _list(String path) async {
    try {
      final json = await api.get(path, auth: true);
      final raw = json['items'] as List<dynamic>? ?? const [];
      return [
        for (final item in raw)
          PromoEvent.fromJson(item as Map<String, dynamic>),
      ];
    } on AppException catch (e) {
      throw failureFromException(e);
    }
  }

  @override
  Future<PromoEvent> createEvent(PromoEventInput input) async {
    try {
      final banner = await _resolveBanner(input.bannerImageUrl);
      final json = await api.post(
        ApiEndpoints.managementEvents,
        auth: true,
        body: _body(input, banner),
      );
      return PromoEvent.fromJson(json);
    } on AppException catch (e) {
      throw failureFromException(e);
    }
  }

  @override
  Future<PromoEvent> updateEvent(String id, PromoEventInput input) async {
    try {
      final banner = await _resolveBanner(input.bannerImageUrl);
      final json = await api.patch(
        ApiEndpoints.managementEventById(id),
        auth: true,
        body: _body(input, banner),
      );
      return PromoEvent.fromJson(json);
    } on AppException catch (e) {
      throw failureFromException(e);
    }
  }

  @override
  Future<PromoEvent> setEventPublished(String id, bool isPublished) async {
    try {
      final json = await api.patch(
        ApiEndpoints.managementEventById(id),
        auth: true,
        body: {'is_published': isPublished},
      );
      return PromoEvent.fromJson(json);
    } on AppException catch (e) {
      throw failureFromException(e);
    }
  }

  @override
  Future<List<PromoOption>> fetchPromoOptions() async {
    try {
      final json = await api.get(
        ApiEndpoints.managementEventPromoOptions,
        auth: true,
      );
      final raw = json['items'] as List<dynamic>? ?? const [];
      return [
        for (final item in raw)
          PromoOption.fromJson(item as Map<String, dynamic>),
      ];
    } on AppException catch (e) {
      throw failureFromException(e);
    }
  }

  /// Path lokal diunggah dulu ke R2 dan diganti URL publiknya; URL http
  /// dipakai apa adanya; kosong berarti banner dihapus.
  Future<String?> _resolveBanner(String? banner) async {
    final value = banner?.trim() ?? '';
    if (value.isEmpty) return null;
    if (value.startsWith('http')) return value;

    final json = await api.postMultipart(
      ApiEndpoints.eventBanner,
      fields: const {},
      fileField: 'image',
      filePath: value,
      auth: true,
    );
    final url = json['image_url'] as String?;
    if (url == null || url.isEmpty) {
      throw const Failure(FailureType.unknown, AppStrings.errUnknown);
    }
    return url;
  }

  Map<String, dynamic> _body(PromoEventInput input, String? banner) {
    final description = input.description?.trim() ?? '';
    return {
      'title': input.title.trim(),
      'event_type': input.type.toJson(),
      'description': description.isEmpty ? null : description,
      'banner_image_url': banner,
      'related_promo_id': input.relatedPromoId,
      'start_date': _date(input.startDate),
      'end_date': _date(input.endDate),
      'is_published': input.isPublished,
    };
  }

  String? _date(DateTime? value) {
    if (value == null) return null;
    String p(int n) => n.toString().padLeft(2, '0');
    return '${value.year}-${p(value.month)}-${p(value.day)}';
  }
}
