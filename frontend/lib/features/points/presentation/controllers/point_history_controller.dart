import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:rijiki/app/providers.dart';
import 'package:rijiki/features/points/domain/point_ledger_entry.dart';

Duration? _noRetry(int retryCount, Object error) => null;

final pointBalanceProvider = FutureProvider.autoDispose<PointBalance>((ref) {
  return ref.watch(customerPointsRepositoryProvider).fetchBalance();
}, retry: _noRetry);

@immutable
class PointLedgerState {
  const PointLedgerState({
    required this.items,
    required this.total,
    this.page = 1,
    this.loadingMore = false,
    this.loadMoreFailed = false,
  });

  final List<PointLedgerEntry> items;
  final int total;
  final int page;
  final bool loadingMore;
  final bool loadMoreFailed;

  bool get hasMore => items.length < total;

  PointLedgerState copyWith({
    List<PointLedgerEntry>? items,
    int? total,
    int? page,
    bool? loadingMore,
    bool? loadMoreFailed,
  }) {
    return PointLedgerState(
      items: items ?? this.items,
      total: total ?? this.total,
      page: page ?? this.page,
      loadingMore: loadingMore ?? this.loadingMore,
      loadMoreFailed: loadMoreFailed ?? this.loadMoreFailed,
    );
  }
}

class PointLedgerNotifier extends AsyncNotifier<PointLedgerState> {
  static const int _limit = 20;

  @override
  Future<PointLedgerState> build() async {
    final page = await ref
        .read(customerPointsRepositoryProvider)
        .fetchLedger(page: 1, limit: _limit);
    return PointLedgerState(items: page.items, total: page.total);
  }

  Future<void> loadMore() async {
    final current = state.value;
    if (current == null || current.loadingMore || !current.hasMore) return;

    state = AsyncData(
      current.copyWith(loadingMore: true, loadMoreFailed: false),
    );
    try {
      final nextPage = current.page + 1;
      final page = await ref
          .read(customerPointsRepositoryProvider)
          .fetchLedger(page: nextPage, limit: _limit);
      if (!ref.mounted) return;
      final known = {for (final e in current.items) e.id};
      state = AsyncData(
        current.copyWith(
          items: [
            ...current.items,
            for (final e in page.items)
              if (!known.contains(e.id)) e,
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

final pointLedgerProvider =
    AsyncNotifierProvider.autoDispose<PointLedgerNotifier, PointLedgerState>(
      PointLedgerNotifier.new,
      retry: _noRetry,
    );
