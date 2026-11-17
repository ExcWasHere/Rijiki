import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:rijiki/core/session/session_provider.dart';
import 'package:rijiki/core/theme/app_colors.dart';
import 'package:rijiki/core/theme/app_spacing.dart';
import 'package:rijiki/features/notifications/domain/app_notification.dart';
import 'package:rijiki/features/notifications/presentation/controllers/notification_list_controller.dart';
import 'package:rijiki/features/notifications/presentation/utils/notification_format.dart';
import 'package:rijiki/features/notifications/presentation/utils/notification_route.dart';
import 'package:rijiki/shared/widgets/empty_state.dart';
import 'package:rijiki/shared/widgets/error_state.dart';
import 'package:rijiki/shared/widgets/loading_skeleton.dart';

/// Inbox notifikasi semua role: status order, pembayaran, dan tukar poin.
class NotificationsPage extends ConsumerStatefulWidget {
  const NotificationsPage({super.key});

  @override
  ConsumerState<NotificationsPage> createState() => _NotificationsPageState();
}

class _NotificationsPageState extends ConsumerState<NotificationsPage> {
  final ScrollController _scroll = ScrollController();

  @override
  void initState() {
    super.initState();
    _scroll.addListener(_onScroll);
  }

  @override
  void dispose() {
    _scroll
      ..removeListener(_onScroll)
      ..dispose();
    super.dispose();
  }

  void _onScroll() {
    if (!_scroll.hasClients) return;
    final position = _scroll.position;
    if (position.pixels >= position.maxScrollExtent - 240) {
      ref.read(notificationListProvider.notifier).loadMore();
    }
  }

  Future<void> _refresh() async {
    ref.invalidate(notificationListProvider);
    ref.invalidate(unreadNotificationCountProvider);
    try {
      await ref.read(notificationListProvider.future);
    } catch (_) {}
  }

  Future<void> _markAllRead() async {
    final messenger = ScaffoldMessenger.of(context);
    try {
      await ref.read(notificationListProvider.notifier).markAllRead();
    } catch (_) {
      messenger
        ..hideCurrentSnackBar()
        ..showSnackBar(
          const SnackBar(content: Text('Gagal menandai semua notifikasi.')),
        );
    }
  }

  void _open(AppNotification notification) {
    ref.read(notificationListProvider.notifier).markRead(notification);

    final role = ref.read(sessionProvider)?.role;
    if (role == null) return;
    final target = notificationTarget(
      role: role,
      type: notification.type,
      data: notification.data,
    );
    if (target != null) openNotificationTarget(GoRouter.of(context), target);
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(notificationListProvider);
    final data = state.value;
    final unread = data?.unread ?? 0;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Notifikasi'),
        actions: [
          if (unread > 0)
            TextButton(
              onPressed: _markAllRead,
              child: const Text('Tandai dibaca'),
            ),
        ],
      ),
      body: RefreshIndicator(
        color: AppColors.primaryDark,
        onRefresh: _refresh,
        child: ListView(
          controller: _scroll,
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.fromLTRB(
            AppSpacing.md,
            AppSpacing.md,
            AppSpacing.md,
            AppSpacing.xl,
          ),
          children: [
            if (data != null)
              _NotificationList(
                state: data,
                onOpen: _open,
                onRetryMore: () =>
                    ref.read(notificationListProvider.notifier).loadMore(),
              )
            else if (state.hasError)
              ErrorState(
                message: 'Gagal memuat notifikasi.',
                onRetry: () => ref.invalidate(notificationListProvider),
              )
            else
              const Column(
                children: [
                  LoadingSkeleton(height: 76, radius: AppSpacing.radiusMd),
                  SizedBox(height: AppSpacing.sm),
                  LoadingSkeleton(height: 76, radius: AppSpacing.radiusMd),
                  SizedBox(height: AppSpacing.sm),
                  LoadingSkeleton(height: 76, radius: AppSpacing.radiusMd),
                ],
              ),
          ],
        ),
      ),
    );
  }
}

class _NotificationList extends StatelessWidget {
  const _NotificationList({
    required this.state,
    required this.onOpen,
    required this.onRetryMore,
  });

  final NotificationListState state;
  final ValueChanged<AppNotification> onOpen;
  final VoidCallback onRetryMore;

  @override
  Widget build(BuildContext context) {
    if (state.items.isEmpty) {
      return const Padding(
        padding: EdgeInsets.only(top: AppSpacing.lg),
        child: EmptyState(
          icon: Icons.notifications_none_rounded,
          title: 'Belum ada notifikasi',
          message:
              'Kabar status order, pembayaran, dan poin akan muncul di sini.',
        ),
      );
    }

    return Column(
      children: [
        Container(
          clipBehavior: Clip.antiAlias,
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
            border: Border.all(color: AppColors.outline.withValues(alpha: 0.3)),
          ),
          child: Column(
            children: [
              for (var i = 0; i < state.items.length; i++) ...[
                if (i > 0)
                  Divider(
                    height: 1,
                    indent: AppSpacing.md,
                    endIndent: AppSpacing.md,
                    color: AppColors.outline.withValues(alpha: 0.2),
                  ),
                _NotificationTile(
                  notification: state.items[i],
                  onTap: () => onOpen(state.items[i]),
                ),
              ],
            ],
          ),
        ),
        const SizedBox(height: AppSpacing.md),
        if (state.loadingMore)
          const Padding(
            padding: EdgeInsets.all(AppSpacing.sm),
            child: SizedBox(
              width: 22,
              height: 22,
              child: CircularProgressIndicator(strokeWidth: 2),
            ),
          )
        else if (state.loadMoreFailed)
          TextButton.icon(
            onPressed: onRetryMore,
            icon: const Icon(Icons.refresh_rounded),
            label: const Text('Gagal memuat, coba lagi'),
          )
        else if (!state.hasMore)
          Text(
            'Semua notifikasi sudah tampil',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: AppColors.onSurfaceVariant,
            ),
          ),
      ],
    );
  }
}

class _NotificationTile extends StatelessWidget {
  const _NotificationTile({required this.notification, required this.onTap});

  final AppNotification notification;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final muted = textTheme.bodySmall?.copyWith(
      color: AppColors.onSurfaceVariant,
    );
    final color = notification.type.color;

    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.md,
          vertical: AppSpacing.sm + 4,
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(notification.type.icon, size: 22, color: color),
            ),
            const SizedBox(width: AppSpacing.sm + 4),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: Text(
                          notification.title,
                          style: textTheme.titleSmall?.copyWith(
                            fontWeight: notification.read
                                ? FontWeight.w600
                                : FontWeight.w800,
                          ),
                        ),
                      ),
                      if (!notification.read) ...[
                        const SizedBox(width: AppSpacing.sm),
                        Container(
                          width: 8,
                          height: 8,
                          margin: const EdgeInsets.only(top: 6),
                          decoration: const BoxDecoration(
                            color: AppColors.rijikiOrange,
                            shape: BoxShape.circle,
                          ),
                        ),
                      ],
                    ],
                  ),
                  const SizedBox(height: 2),
                  Text(notification.body, style: muted),
                  const SizedBox(height: 2),
                  Text(notification.timeLabel, style: muted),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
