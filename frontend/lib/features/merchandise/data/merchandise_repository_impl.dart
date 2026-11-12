import 'package:rijiki/core/constants/app_strings.dart';
import 'package:rijiki/core/error/app_exception.dart';
import 'package:rijiki/core/error/failure.dart';
import 'package:rijiki/core/error/failure_mapper.dart';
import 'package:rijiki/core/network/api_client.dart';
import 'package:rijiki/core/network/api_endpoint.dart';
import 'package:rijiki/features/merchandise/domain/merchandise.dart';
import 'package:rijiki/features/merchandise/domain/merchandise_input.dart';
import 'package:rijiki/features/merchandise/domain/merchandise_repository.dart';

class MerchandiseRepositoryImpl implements MerchandiseRepository {
  MerchandiseRepositoryImpl({required this.api});

  final ApiClient api;

  /// Katalog customer memakai GET /api/points/rewards (lihat
  /// CustomerPointsRepository). Metode ini menyaring daftar manajemen.
  @override
  Future<List<Merchandise>> fetchActiveMerchandise() async {
    final all = await fetchAllMerchandise();
    return [
      for (final item in all)
        if (item.isActive) item,
    ];
  }

  @override
  Future<List<Merchandise>> fetchAllMerchandise() async {
    try {
      final json = await api.get(ApiEndpoints.managementMerchandise, auth: true);
      final raw = json['items'] as List<dynamic>? ?? const [];
      return [
        for (final item in raw)
          Merchandise.fromJson(item as Map<String, dynamic>),
      ];
    } on AppException catch (e) {
      throw failureFromException(e);
    }
  }

  @override
  Future<Merchandise> createMerchandise(MerchandiseInput input) async {
    try {
      final image = await _resolveImage(input.imageUrl);
      final json = await api.post(
        ApiEndpoints.managementMerchandise,
        auth: true,
        body: _body(input, image),
      );
      return Merchandise.fromJson(json);
    } on AppException catch (e) {
      throw failureFromException(e);
    }
  }

  @override
  Future<Merchandise> updateMerchandise(
    String id,
    MerchandiseInput input,
  ) async {
    try {
      final image = await _resolveImage(input.imageUrl);
      final json = await api.patch(
        ApiEndpoints.managementMerchandiseById(id),
        auth: true,
        body: _body(input, image),
      );
      return Merchandise.fromJson(json);
    } on AppException catch (e) {
      throw failureFromException(e);
    }
  }

  @override
  Future<Merchandise> setMerchandiseActive(String id, bool isActive) async {
    try {
      final json = await api.patch(
        ApiEndpoints.managementMerchandiseById(id),
        auth: true,
        body: {'is_active': isActive},
      );
      return Merchandise.fromJson(json);
    } on AppException catch (e) {
      throw failureFromException(e);
    }
  }

  /// Path lokal diunggah dulu ke R2 dan diganti URL publiknya; URL http
  /// dipakai apa adanya; kosong berarti foto dihapus.
  Future<String?> _resolveImage(String? image) async {
    final value = image?.trim() ?? '';
    if (value.isEmpty) return null;
    if (value.startsWith('http')) return value;

    final json = await api.postMultipart(
      ApiEndpoints.merchandiseImage,
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

  Map<String, dynamic> _body(MerchandiseInput input, String? image) {
    final description = input.description?.trim() ?? '';
    return {
      'name': input.name.trim(),
      'description': description.isEmpty ? null : description,
      'price': input.price,
      'points_cost': input.pointsCost,
      'stock_quantity': input.stockQuantity,
      'image_url': image,
      'is_active': input.isActive,
    };
  }
}
