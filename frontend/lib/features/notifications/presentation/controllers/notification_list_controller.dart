import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:rijiki/app/providers.dart';
import 'package:rijiki/features/notifications/domain/app_notification.dart';

Duration? _noRetry(int retryCount, Object error) => null;

/// Jumlah notifikasi belum dibaca; dipakai badge di kartu profil.
final unreadNotificationCountProvider = FutureProvider.autoDispose<int>((
  ref,
) {
  return ref.watch(notificationRepositoryProvider).fetchUnreadCount();
}, retry: _noRetry);

@immutable
class NotificationListState {
  const NotificationListState({
    required this.items,
    required this.total,
    required this.unread,
    this.page = 1,
    this.loadingMore = false,
    this.loadMoreFailed = false,
  });

  final List<AppNotification> items;
  final int total;
  final int unread;
  final int page;
  final bool loadingMore;
  final bool loadMoreFailed;

  bool get hasMore => items.length < total;

  NotificationListState copyWith({
    List<AppNotification>? items,
    int? total,
    int? unread,
    int? page,
    bool? loadingMore,
    bool? loadMoreFailed,
  }) {
    return NotificationListState(
      items: items ?? this.items,
      total: total ?? this.total,
      unread: unread ?? this.unread,
      page: page ?? this.page,
      loadingMore: loadingMore ?? this.loadingMore,
      loadMoreFailed: loadMoreFailed ?? this.loadMoreFailed,
    );
  }
}

class NotificationListNotifier extends AsyncNotifier<NotificationListState> {
  static const int _limit = 20;

  @override
  Future<NotificationListState> build() async {
    final page = await ref
        .read(notificationRepositoryProvider)
        .fetch(page: 1, limit: _limit);
    return NotificationListState(
      items: page.items,
      total: page.total,
      unread: page.unread,
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
      final page = await ref
          .read(notificationRepositoryProvider)
          .fetch(page: nextPage, limit: _limit);
      if (!ref.mounted) return;

      final known = {for (final item in current.items) item.id};
      state = AsyncData(
        current.copyWith(
          items: [
            ...current.items,
            for (final item in page.items)
              if (!known.contains(item.id)) item,
          ],
          total: page.total,
          unread: page.unread,
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

  /// Menandai satu notifikasi dibaca. Galat diabaikan: daftar tetap bisa dibaca.
  Future<void> markRead(AppNotification notification) async {
    final current = state.value;
    if (current == null || notification.read) return;

    state = AsyncData(
      current.copyWith(
        items: [
          for (final item in current.items)
            item.id == notification.id ? item.copyWith(read: true) : item,
        ],
        unread: current.unread > 0 ? current.unread - 1 : 0,
      ),
    );
    ref.invalidate(unreadNotificationCountProvider);

    try {
      await ref.read(notificationRepositoryProvider).markRead(notification.id);
    } catch (_) {
      // Biarkan tampil terbaca; backend akan mengoreksi saat daftar dimuat ulang.
    }
  }

  Future<void> markAllRead() async {
    final current = state.value;
    if (current == null || current.unread == 0) return;

    state = AsyncData(
      current.copyWith(
        items: [for (final item in current.items) item.copyWith(read: true)],
        unread: 0,
      ),
    );
    ref.invalidate(unreadNotificationCountProvider);
    await ref.read(notificationRepositoryProvider).markAllRead();
  }
}

final notificationListProvider =
    AsyncNotifierProvider.autoDispose<
      NotificationListNotifier,
      NotificationListState
    >(NotificationListNotifier.new, retry: _noRetry);
