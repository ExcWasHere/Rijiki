import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:rijiki/app/providers.dart';
import 'package:rijiki/core/error/failure.dart';
import 'package:rijiki/features/cms/presentation/controllers/cms_action_state.dart';
import 'package:rijiki/features/rating/domain/managed_rating.dart';

String _messageFor(Object error, String fallback) {
  if (error is Failure && error.message.trim().isNotEmpty) return error.message;
  return fallback;
}

class TestimonialFilterNotifier extends Notifier<RatingListFilter> {
  @override
  RatingListFilter build() => RatingListFilter.all;

  void set(RatingListFilter filter) => state = filter;
}

final testimonialFilterProvider =
    NotifierProvider.autoDispose<TestimonialFilterNotifier, RatingListFilter>(
      TestimonialFilterNotifier.new,
    );

@immutable
class TestimonialList {
  const TestimonialList({
    required this.items,
    required this.total,
    required this.page,
    required this.summary,
    this.loadingMore = false,
  });

  final List<ManagedRating> items;
  final int total;
  final int page;
  final RatingSummary summary;
  final bool loadingMore;

  bool get hasMore => items.length < total;

  TestimonialList copyWith({
    List<ManagedRating>? items,
    int? total,
    int? page,
    RatingSummary? summary,
    bool? loadingMore,
  }) {
    return TestimonialList(
      items: items ?? this.items,
      total: total ?? this.total,
      page: page ?? this.page,
      summary: summary ?? this.summary,
      loadingMore: loadingMore ?? this.loadingMore,
    );
  }
}

class TestimonialListController extends AsyncNotifier<TestimonialList> {
  @override
  Future<TestimonialList> build() async {
    final filter = ref.watch(testimonialFilterProvider);
    final page = await ref
        .read(testimonialManageRepositoryProvider)
        .fetchRatings(filter);
    return TestimonialList(
      items: page.items,
      total: page.total,
      page: page.page,
      summary: page.summary,
    );
  }

  Future<void> loadMore() async {
    final current = state.value;
    if (current == null || !current.hasMore || current.loadingMore) return;
    state = AsyncData(current.copyWith(loadingMore: true));
    try {
      final next = await ref
          .read(testimonialManageRepositoryProvider)
          .fetchRatings(
            ref.read(testimonialFilterProvider),
            page: current.page + 1,
          );
      if (!ref.mounted) return;
      state = AsyncData(
        current.copyWith(
          items: [...current.items, ...next.items],
          total: next.total,
          page: next.page,
          summary: next.summary,
          loadingMore: false,
        ),
      );
    } catch (_) {
      if (!ref.mounted) return;
      state = AsyncData(current.copyWith(loadingMore: false));
    }
  }
}

final testimonialListProvider =
    AsyncNotifierProvider.autoDispose<TestimonialListController, TestimonialList>(
      TestimonialListController.new,
    );

class TestimonialActionNotifier extends Notifier<CmsActionState> {
  @override
  CmsActionState build() => const CmsActionState();

  Future<bool> setFeatured(ManagedRating rating, bool value) async {
    if (state.busyId != null) return false;
    state = CmsActionState(busyId: rating.id, busyValue: value);
    try {
      await ref
          .read(testimonialManageRepositoryProvider)
          .setFeatured(rating.id, value);
      if (!ref.mounted) return true;
      ref.invalidate(testimonialListProvider);
      await ref.read(testimonialListProvider.future);
      if (!ref.mounted) return true;
      state = const CmsActionState();
      return true;
    } catch (e) {
      if (!ref.mounted) return false;
      state = CmsActionState(
        errorMessage: _messageFor(
          e,
          'Gagal mengubah testimoni pilihan. Coba lagi ya.',
        ),
      );
      return false;
    }
  }
}

final testimonialActionProvider =
    NotifierProvider.autoDispose<TestimonialActionNotifier, CmsActionState>(
      TestimonialActionNotifier.new,
    );

@immutable
class RecapExportState {
  const RecapExportState({this.busy = false, this.error});

  final bool busy;
  final String? error;
}

class RecapExportNotifier extends Notifier<RecapExportState> {
  @override
  RecapExportState build() => const RecapExportState();

  Future<RecapFile?> run(RecapRequest request) async {
    if (state.busy) return null;
    state = const RecapExportState(busy: true);
    try {
      final file = await ref
          .read(testimonialManageRepositoryProvider)
          .downloadRecap(request);
      if (!ref.mounted) return file;
      state = const RecapExportState();
      return file;
    } catch (e) {
      if (!ref.mounted) return null;
      state = RecapExportState(
        error: _messageFor(e, 'Rekap gagal dibuat. Coba lagi ya.'),
      );
      return null;
    }
  }
}

final recapExportProvider =
    NotifierProvider.autoDispose<RecapExportNotifier, RecapExportState>(
      RecapExportNotifier.new,
    );
