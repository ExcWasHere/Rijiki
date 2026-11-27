import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:rijiki/app/providers.dart';
import 'package:rijiki/features/profile/domain/profile_history.dart';

Duration? _noRetry(int retryCount, Object error) => null;

@immutable
class HistoryPage<T> {
  const HistoryPage({required this.items, required this.total, this.average});

  final List<T> items;
  final int total;
  final double? average;
}

@immutable
class HistoryList<T> {
  const HistoryList({
    required this.items,
    required this.total,
    this.average,
    this.page = 1,
    this.loadingMore = false,
    this.loadMoreFailed = false,
  });

  final List<T> items;
  final int total;
  final double? average;
  final int page;
  final bool loadingMore;
  final bool loadMoreFailed;

  bool get hasMore => items.length < total;

  HistoryList<T> copyWith({
    List<T>? items,
    int? total,
    double? average,
    int? page,
    bool? loadingMore,
    bool? loadMoreFailed,
  }) {
    return HistoryList<T>(
      items: items ?? this.items,
      total: total ?? this.total,
      average: average ?? this.average,
      page: page ?? this.page,
      loadingMore: loadingMore ?? this.loadingMore,
      loadMoreFailed: loadMoreFailed ?? this.loadMoreFailed,
    );
  }
}

/// Daftar riwayat profil dengan muat-bertahap. Subclass hanya menyediakan
/// [fetchPage]; sisanya (paginasi, status gagal) sama untuk semua riwayat.
abstract class PagedHistoryNotifier<T> extends AsyncNotifier<HistoryList<T>> {
  static const int pageSize = 20;

  Future<HistoryPage<T>> fetchPage(int page);

  /// Kunci unik baris, dipakai agar halaman berikutnya tidak menggandakan baris.
  String idOf(T item);

  @override
  Future<HistoryList<T>> build() async {
    final page = await fetchPage(1);
    return HistoryList<T>(
      items: page.items,
      total: page.total,
      average: page.average,
    );
  }

  Future<void> loadMore() async {
    final current = state.value;
    if (current == null || current.loadingMore || !current.hasMore) return;

    state = AsyncData(
      current.copyWith(loadingMore: true, loadMoreFailed: false),
    );
    try {
      final nextPage = current.page + 1;
      final page = await fetchPage(nextPage);
      if (!ref.mounted) return;

      final known = {for (final item in current.items) idOf(item)};
      state = AsyncData(
        current.copyWith(
          items: [
            ...current.items,
            for (final item in page.items)
              if (!known.contains(idOf(item))) item,
          ],
          total: page.total,
          page: nextPage,
          loadingMore: false,
        ),
      );
    } catch (_) {
      if (!ref.mounted) return;
      state = AsyncData(
        current.copyWith(loadingMore: false, loadMoreFailed: true),
      );
    }
  }
}

class MyShoesNotifier extends PagedHistoryNotifier<MyShoe> {
  @override
  String idOf(MyShoe item) => item.id;

  @override
  Future<HistoryPage<MyShoe>> fetchPage(int page) async {
    final result = await ref
        .read(profileRepositoryProvider)
        .fetchMyShoes(page: page, limit: PagedHistoryNotifier.pageSize);
    return HistoryPage(items: result.items, total: result.total);
  }
}

class MyRatingsNotifier extends PagedHistoryNotifier<CustomerRating> {
  @override
  String idOf(CustomerRating item) => item.id;

  @override
  Future<HistoryPage<CustomerRating>> fetchPage(int page) async {
    final result = await ref
        .read(profileRepositoryProvider)
        .fetchMyRatings(page: page, limit: PagedHistoryNotifier.pageSize);
    return HistoryPage(
      items: result.items,
      total: result.total,
      average: result.average,
    );
  }
}

final myShoesProvider =
    AsyncNotifierProvider.autoDispose<MyShoesNotifier, HistoryList<MyShoe>>(
      MyShoesNotifier.new,
      retry: _noRetry,
    );

final myRatingsProvider =
    AsyncNotifierProvider.autoDispose<
      MyRatingsNotifier,
      HistoryList<CustomerRating>
    >(MyRatingsNotifier.new, retry: _noRetry);
