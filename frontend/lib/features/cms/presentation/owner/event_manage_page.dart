import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:rijiki/app/router/route_paths.dart';
import 'package:rijiki/core/theme/app_colors.dart';
import 'package:rijiki/core/theme/app_spacing.dart';
import 'package:rijiki/features/cms/presentation/controllers/cms_action_state.dart';
import 'package:rijiki/features/cms/presentation/controllers/event_manage_controller.dart';
import 'package:rijiki/features/cms/presentation/utils/event_format.dart';
import 'package:rijiki/features/cms/presentation/widgets/cms_filter_bar.dart';
import 'package:rijiki/features/cms/presentation/widgets/cms_item_tile.dart';
import 'package:rijiki/features/cms/presentation/widgets/cms_state_card.dart';
import 'package:rijiki/features/cms/presentation/widgets/cms_thumbnail.dart';
import 'package:rijiki/features/event/domain/promo_event.dart';
import 'package:rijiki/shared/widgets/empty_state.dart';
import 'package:rijiki/shared/widgets/error_state.dart';
import 'package:rijiki/shared/widgets/loading_skeleton.dart';

class EventManagePage extends ConsumerStatefulWidget {
  const EventManagePage({super.key});

  @override
  ConsumerState<EventManagePage> createState() => _EventManagePageState();
}

class _EventManagePageState extends ConsumerState<EventManagePage> {
  final TextEditingController _search = TextEditingController();

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  Future<void> _toggle(PromoEvent event, bool published) async {
    final messenger = ScaffoldMessenger.of(context);

    if (!published) {
      final confirmed = await showDialog<bool>(
        context: context,
        builder: (dialogContext) => AlertDialog(
          title: Text('Sembunyikan ${event.title}?'),
          content: const Text(
            'Event tidak akan tampil lagi di aplikasi customer. Datanya '
            'tetap tersimpan dan bisa ditayangkan kembali kapan saja.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext, false),
              child: const Text('Batal'),
            ),
            TextButton(
              onPressed: () => Navigator.pop(dialogContext, true),
              child: const Text('Sembunyikan'),
            ),
          ],
        ),
      );
      if (confirmed != true) return;
    }

    final ok = await ref
        .read(eventManageProvider.notifier)
        .setPublished(event, published);
    if (!mounted) return;

    final message = ok
        ? '${event.title} ${published ? 'ditayangkan' : 'disembunyikan'}.'
        : (ref.read(eventManageProvider).errorMessage ??
              'Gagal mengubah status.');
    messenger
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  Widget build(BuildContext context) {
    final async = ref.watch(cmsEventsProvider);
    final all = async.value;
    final filter = ref.watch(eventManageFilterProvider);
    final counts = ref.watch(cmsEventCountsProvider);
    final visible = ref.watch(filteredCmsEventsProvider);
    final manage = ref.watch(eventManageProvider);
    final notifier = ref.read(eventManageFilterProvider.notifier);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(title: const Text('Event')),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => context.push(RoutePaths.ownerCmsEventNew),
        backgroundColor: AppColors.primary,
        foregroundColor: AppColors.onPrimary,
        icon: const Icon(Icons.add_rounded),
        label: const Text('Tambah event'),
      ),
      body: RefreshIndicator(
        color: AppColors.primaryDark,
        onRefresh: () async {
          ref.invalidate(cmsEventsProvider);
          try {
            await ref.read(cmsEventsProvider.future);
          } catch (_) {}
        },
        child: ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.fromLTRB(
            AppSpacing.lg,
            AppSpacing.md,
            AppSpacing.lg,
            96,
          ),
          children: [
            CmsFilterBar(
              controller: _search,
              hint: 'Cari event',
              status: filter.status,
              counts: counts,
              onQueryChanged: notifier.setQuery,
              onStatusChanged: notifier.setStatus,
            ),
            const SizedBox(height: AppSpacing.md),
            if (all != null)
              AnimatedOpacity(
                duration: const Duration(milliseconds: 200),
                opacity: async.isLoading ? 0.55 : 1,
                child: _Content(
                  all: all,
                  visible: visible,
                  manage: manage,
                  onTap: (event) =>
                      context.push(RoutePaths.ownerCmsEventEditFor(event.id)),
                  onToggle: _toggle,
                  onAdd: () => context.push(RoutePaths.ownerCmsEventNew),
                  onReset: () {
                    _search.clear();
                    notifier.reset();
                  },
                ),
              )
            else if (async.hasError)
              CmsStateCard(
                child: ErrorState(
                  message: 'Gagal memuat event.',
                  onRetry: () => ref.invalidate(cmsEventsProvider),
                ),
              )
            else
              const LoadingSkeleton(height: 360, radius: AppSpacing.radiusLg),
          ],
        ),
      ),
    );
  }
}

class _Content extends StatelessWidget {
  const _Content({
    required this.all,
    required this.visible,
    required this.manage,
    required this.onTap,
    required this.onToggle,
    required this.onAdd,
    required this.onReset,
  });

  final List<PromoEvent> all;
  final List<PromoEvent> visible;
  final CmsActionState manage;
  final ValueChanged<PromoEvent> onTap;
  final Future<void> Function(PromoEvent event, bool published) onToggle;
  final VoidCallback onAdd;
  final VoidCallback onReset;

  @override
  Widget build(BuildContext context) {
    if (all.isEmpty) {
      return CmsStateCard(
        child: EmptyState(
          icon: Icons.event_rounded,
          title: 'Belum ada event',
          message: 'Tambahkan event, kolaborasi, atau pengumuman pertama.',
          actionLabel: 'Tambah event',
          onAction: onAdd,
        ),
      );
    }
    if (visible.isEmpty) {
      return CmsStateCard(
        child: EmptyState(
          icon: Icons.search_off_rounded,
          title: 'Event tidak ditemukan',
          actionLabel: 'Reset pencarian',
          onAction: onReset,
        ),
      );
    }

    final textTheme = Theme.of(context).textTheme;

    return Container(
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
        border: Border.all(color: AppColors.outline.withValues(alpha: 0.3)),
      ),
      child: Material(
        color: AppColors.surface,
        child: Column(
          children: [
            for (var i = 0; i < visible.length; i++) ...[
              if (i > 0)
                Divider(
                  height: 1,
                  indent: AppSpacing.md,
                  endIndent: AppSpacing.md,
                  color: AppColors.outline.withValues(alpha: 0.2),
                ),
              Builder(
                builder: (context) {
                  final event = visible[i];
                  final busy = manage.busyId == event.id;
                  return CmsItemTile(
                    leading: CmsThumbnail(
                      url: event.bannerImageUrl,
                      fallbackIcon: event.type.cmsIcon,
                      fallbackColor: event.type.cmsColor,
                    ),
                    title: event.title,
                    details: [
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color: event.type.cmsColor.withValues(alpha: 0.12),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              event.type.cmsLabel,
                              style: textTheme.labelSmall?.copyWith(
                                color: event.type.cmsColor,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              formatEventPeriod(event.startDate, event.endDate),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: textTheme.bodySmall?.copyWith(
                                color: AppColors.onSurfaceVariant,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                    isActive: busy
                        ? (manage.busyValue ?? event.isPublished)
                        : event.isPublished,
                    busy: busy,
                    inactiveLabel: 'Disembunyikan · tidak tampil di customer',
                    onTap: () => onTap(event),
                    onToggle: (value) => onToggle(event, value),
                  );
                },
              ),
            ],
          ],
        ),
      ),
    );
  }
}
