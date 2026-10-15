import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:rijiki/app/router/route_paths.dart';
import 'package:rijiki/core/theme/app_colors.dart';
import 'package:rijiki/core/theme/app_spacing.dart';
import 'package:rijiki/core/utils/rupiah_formatter.dart';
import 'package:rijiki/features/cms/presentation/controllers/cms_action_state.dart';
import 'package:rijiki/features/cms/presentation/controllers/merchandise_manage_controller.dart';
import 'package:rijiki/features/cms/presentation/widgets/cms_filter_bar.dart';
import 'package:rijiki/features/cms/presentation/widgets/cms_item_tile.dart';
import 'package:rijiki/features/cms/presentation/widgets/cms_state_card.dart';
import 'package:rijiki/features/cms/presentation/widgets/cms_thumbnail.dart';
import 'package:rijiki/features/merchandise/domain/merchandise.dart';
import 'package:rijiki/shared/widgets/empty_state.dart';
import 'package:rijiki/shared/widgets/error_state.dart';
import 'package:rijiki/shared/widgets/loading_skeleton.dart';

class MerchandiseManagePage extends ConsumerStatefulWidget {
  const MerchandiseManagePage({super.key});

  @override
  ConsumerState<MerchandiseManagePage> createState() =>
      _MerchandiseManagePageState();
}

class _MerchandiseManagePageState extends ConsumerState<MerchandiseManagePage> {
  final TextEditingController _search = TextEditingController();

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  Future<void> _toggle(Merchandise item, bool active) async {
    final messenger = ScaffoldMessenger.of(context);

    if (!active) {
      final confirmed = await showDialog<bool>(
        context: context,
        builder: (dialogContext) => AlertDialog(
          title: Text('Nonaktifkan ${item.name}?'),
          content: const Text(
            'Merchandise tidak akan tampil lagi di katalog customer. Datanya '
            'tetap tersimpan dan bisa diaktifkan kembali kapan saja.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext, false),
              child: const Text('Batal'),
            ),
            TextButton(
              onPressed: () => Navigator.pop(dialogContext, true),
              child: const Text('Nonaktifkan'),
            ),
          ],
        ),
      );
      if (confirmed != true) return;
    }

    final ok = await ref
        .read(merchandiseManageProvider.notifier)
        .setActive(item, active);
    if (!mounted) return;

    final message = ok
        ? '${item.name} ${active ? 'diaktifkan' : 'dinonaktifkan'}.'
        : (ref.read(merchandiseManageProvider).errorMessage ??
              'Gagal mengubah status.');
    messenger
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  Widget build(BuildContext context) {
    final async = ref.watch(cmsMerchandiseProvider);
    final all = async.value;
    final filter = ref.watch(merchandiseManageFilterProvider);
    final counts = ref.watch(cmsMerchandiseCountsProvider);
    final visible = ref.watch(filteredCmsMerchandiseProvider);
    final manage = ref.watch(merchandiseManageProvider);
    final notifier = ref.read(merchandiseManageFilterProvider.notifier);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(title: const Text('Merchandise')),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => context.push(RoutePaths.ownerCmsMerchandiseNew),
        backgroundColor: AppColors.primary,
        foregroundColor: AppColors.onPrimary,
        icon: const Icon(Icons.add_rounded),
        label: const Text('Tambah merchandise'),
      ),
      body: RefreshIndicator(
        color: AppColors.primaryDark,
        onRefresh: () async {
          ref.invalidate(cmsMerchandiseProvider);
          try {
            await ref.read(cmsMerchandiseProvider.future);
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
              hint: 'Cari merchandise',
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
                  onTap: (item) => context.push(
                    RoutePaths.ownerCmsMerchandiseEditFor(item.id),
                  ),
                  onToggle: _toggle,
                  onAdd: () => context.push(RoutePaths.ownerCmsMerchandiseNew),
                  onReset: () {
                    _search.clear();
                    notifier.reset();
                  },
                ),
              )
            else if (async.hasError)
              CmsStateCard(
                child: ErrorState(
                  message: 'Gagal memuat merchandise.',
                  onRetry: () => ref.invalidate(cmsMerchandiseProvider),
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

  final List<Merchandise> all;
  final List<Merchandise> visible;
  final CmsActionState manage;
  final ValueChanged<Merchandise> onTap;
  final Future<void> Function(Merchandise item, bool active) onToggle;
  final VoidCallback onAdd;
  final VoidCallback onReset;

  @override
  Widget build(BuildContext context) {
    if (all.isEmpty) {
      return CmsStateCard(
        child: EmptyState(
          icon: Icons.card_giftcard_rounded,
          title: 'Belum ada merchandise',
          message: 'Tambahkan merchandise pertama yang bisa ditukar poin.',
          actionLabel: 'Tambah merchandise',
          onAction: onAdd,
        ),
      );
    }
    if (visible.isEmpty) {
      return CmsStateCard(
        child: EmptyState(
          icon: Icons.search_off_rounded,
          title: 'Merchandise tidak ditemukan',
          actionLabel: 'Reset pencarian',
          onAction: onReset,
        ),
      );
    }

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
                  final item = visible[i];
                  final busy = manage.busyId == item.id;
                  return CmsItemTile(
                    leading: CmsThumbnail(
                      url: item.imageUrl,
                      fallbackIcon: Icons.card_giftcard_rounded,
                      fallbackColor: AppColors.primaryDark,
                    ),
                    title: item.name,
                    details: [
                      Text(
                        'Harga referensi ${RupiahFormatter.full(item.price.toDouble())}',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: AppColors.onSurfaceVariant,
                        ),
                      ),
                      Wrap(
                        spacing: 6,
                        runSpacing: 4,
                        children: [
                          _Pill(
                            text: item.pointsCost == null
                                ? 'Belum bisa ditukar'
                                : '${item.pointsCost} poin',
                            color: item.pointsCost == null
                                ? AppColors.onSurfaceVariant
                                : AppColors.rijikiOrange,
                          ),
                          if (item.stockQuantity != null)
                            _Pill(
                              text: item.isOutOfStock
                                  ? 'Stok habis'
                                  : 'Stok ${item.stockQuantity}',
                              color: item.isOutOfStock
                                  ? AppColors.error
                                  : AppColors.success,
                            ),
                        ],
                      ),
                    ],
                    isActive: busy
                        ? (manage.busyValue ?? item.isActive)
                        : item.isActive,
                    busy: busy,
                    inactiveLabel: 'Nonaktif · tidak tampil di katalog',
                    onTap: () => onTap(item),
                    onToggle: (value) => onToggle(item, value),
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

class _Pill extends StatelessWidget {
  const _Pill({required this.text, required this.color});

  final String text;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        text,
        style: Theme.of(context).textTheme.labelSmall?.copyWith(
          color: color == AppColors.onSurfaceVariant
              ? AppColors.onSurfaceVariant
              : AppColors.onSurface,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}
