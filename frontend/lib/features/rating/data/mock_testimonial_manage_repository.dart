import 'dart:typed_data';

import 'package:rijiki/core/mock/mock_scenario.dart';
import 'package:rijiki/features/rating/domain/managed_rating.dart';
import 'package:rijiki/features/rating/domain/testimonial_manage_repository.dart';

class MockTestimonialManageRepository implements TestimonialManageRepository {
  MockTestimonialManageRepository({this.scenario = MockScenario.data});

  final MockScenario scenario;

  static const Duration _writeLatency = Duration(milliseconds: 450);

  late final List<ManagedRating> _ratings = _seed();

  @override
  Future<ManagedRatingPage> fetchRatings(
    RatingListFilter filter, {
    int page = 1,
    int limit = 20,
  }) async {
    final all = await scenario.resolve<List<ManagedRating>>(
      empty: const [],
      data: List.of(_ratings),
    );
    final filtered = [
      for (final r in all)
        if (switch (filter) {
          RatingListFilter.all => true,
          RatingListFilter.featured => r.isFeatured,
          RatingListFilter.withPhoto => r.photoKey != null,
        })
          r,
    ];
    final start = (page - 1) * limit;
    final items = filtered.skip(start).take(limit).toList();
    final average = all.isEmpty
        ? null
        : all.fold<int>(0, (sum, r) => sum + r.ratingValue) / all.length;
    return ManagedRatingPage(
      items: items,
      total: filtered.length,
      page: page,
      summary: RatingSummary(
        total: all.length,
        featured: all.where((r) => r.isFeatured).length,
        average: average,
      ),
    );
  }

  @override
  Future<ManagedRating> setFeatured(String id, bool isFeatured) async {
    await Future<void>.delayed(_writeLatency);
    if (scenario == MockScenario.error) throw const MockException();
    final index = _ratings.indexWhere((r) => r.id == id);
    if (index == -1) throw const MockException('Rating tidak ditemukan');
    final updated = _ratings[index].copyWith(isFeatured: isFeatured);
    _ratings[index] = updated;
    return updated;
  }

  @override
  Future<RecapFile> downloadRecap(RecapRequest request) async {
    await Future<void>.delayed(_writeLatency);
    if (scenario == MockScenario.error) throw const MockException();
    // ZIP kosong yang valid (hanya end-of-central-directory).
    final bytes = Uint8List(22)
      ..[0] = 0x50
      ..[1] = 0x4b
      ..[2] = 0x05
      ..[3] = 0x06;
    return RecapFile(
      bytes: bytes,
      fileName: 'rekap-${request.source.value}-mock.zip',
      total: 0,
      included: 0,
      truncated: false,
    );
  }

  static List<ManagedRating> _seed() {
    final now = DateTime.now();
    return [
      ManagedRating(
        id: 'mr-1',
        orderId: 'o-1',
        orderNumber: 'RJK-1105-003',
        customerName: 'Rina Anggraini',
        workerName: 'Budi S.',
        serviceNames: const ['Deep Clean'],
        ratingValue: 5,
        comment: 'Sneakers putihku balik kayak baru. Dijemput tepat waktu.',
        isFeatured: true,
        createdAt: now.subtract(const Duration(days: 3)),
      ),
      ManagedRating(
        id: 'mr-2',
        orderId: 'o-2',
        orderNumber: 'RJK-1103-011',
        customerName: 'Dimas Pratama',
        workerName: 'Dewi A.',
        serviceNames: const ['Fast Clean', 'Unyellowing'],
        ratingValue: 4,
        comment: 'Cepat, tapi sol belakang masih agak kuning.',
        createdAt: now.subtract(const Duration(days: 5)),
      ),
      ManagedRating(
        id: 'mr-3',
        orderId: 'o-3',
        orderNumber: 'RJK-1101-007',
        customerName: 'Salsa Maharani',
        serviceNames: const ['Reglue'],
        ratingValue: 5,
        createdAt: now.subtract(const Duration(days: 9)),
      ),
    ];
  }
}
