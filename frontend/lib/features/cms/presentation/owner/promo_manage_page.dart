import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:rijiki/app/router/route_paths.dart';
import 'package:rijiki/core/theme/app_colors.dart';
import 'package:rijiki/core/theme/app_spacing.dart';
import 'package:rijiki/features/cms/presentation/controllers/cms_action_state.dart';
import 'package:rijiki/features/cms/presentation/controllers/promo_manage_controller.dart';
import 'package:rijiki/features/cms/presentation/utils/promo_format.dart';
import 'package:rijiki/features/cms/presentation/widgets/cms_filter_bar.dart';
import 'package:rijiki/features/cms/presentation/widgets/cms_item_tile.dart';
import 'package:rijiki/features/cms/presentation/widgets/cms_state_card.dart';
import 'package:rijiki/features/cms/presentation/widgets/promo_discount_badge.dart';
import 'package:rijiki/features/event/domain/promo.dart';
import 'package:rijiki/shared/widgets/empty_state.dart';
import 'package:rijiki/shared/widgets/error_state.dart';
import 'package:rijiki/shared/widgets/loading_skeleton.dart';

class PromoManagePage extends ConsumerStatefulWidget {
  const PromoManagePage({super.key});

  @override
  ConsumerState<PromoManagePage> createState() => _PromoManagePageState();
}

class _PromoManagePageState extends ConsumerState<PromoManagePage> {
  final TextEditingController _search = TextEditingController();

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  Future<void> _toggle(Promo promo, bool active) async {
    final messenger = ScaffoldMessenger.of(context);

    if (!active) {
      final confirmed = await showDialog<bool>(
        context: context,
        builder: (dialogContext) => AlertDialog(
          title: Text('Nonaktifkan ${promo.title}?'),
          content: Text(
            'Kode ${promo.code} tidak bisa dipakai lagi saat order. Order '
            'yang sudah memakai kode ini tidak terpengaruh, dan promo bisa '
            'diaktifkan kembali kapan saja.',
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
        .read(promoManageProvider.notifier)
        .setActive(promo, active);
    if (!mounted) return;

    final message = ok
        ? '${promo.title} ${active ? 'diaktifkan' : 'dinonaktifkan'}.'
        : (ref.read(promoManageProvider).errorMessage ??
              'Gagal mengubah status.');
    messenger
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  Widget build(BuildContext context) {
    final async = ref.watch(cmsPromosProvider);
    final all = async.value;
    final filter = ref.watch(promoManageFilterProvider);
    final counts = ref.watch(cmsPromoCountsProvider);
    final visible = ref.watch(filteredCmsPromosProvider);
    final manage = ref.watch(promoManageProvider);
    final notifier = ref.read(promoManageFilterProvider.notifier);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(title: const Text('Promo')),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => context.push(RoutePaths.ownerCmsPromoNew),
        backgroundColor: AppColors.primary,
        foregroundColor: AppColors.onPrimary,
        icon: const Icon(Icons.add_rounded),
        label: const Text('Tambah promo'),
      ),
      body: RefreshIndicator(
        color: AppColors.primaryDark,
        onRefresh: () async {
          ref.invalidate(cmsPromosProvider);
          try {
            await ref.read(cmsPromosProvider.future);
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
              hint: 'Cari kode atau judul promo',
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
                  onTap: (promo) =>
                      context.push(RoutePaths.ownerCmsPromoEditFor(promo.id)),
                  onToggle: _toggle,
                  onAdd: () => context.push(RoutePaths.ownerCmsPromoNew),
                  onReset: () {
                    _search.clear();
                    notifier.reset();
                  },
                ),
              )
            else if (async.hasError)
              CmsStateCard(
                child: ErrorState(
                  message: 'Gagal memuat promo.',
                  onRetry: () => ref.invalidate(cmsPromosProvider),
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

  final List<Promo> all;
  final List<Promo> visible;
  final CmsActionState manage;
  final ValueChanged<Promo> onTap;
  final Future<void> Function(Promo promo, bool active) onToggle;
  final VoidCallback onAdd;
  final VoidCallback onReset;

  @override
  Widget build(BuildContext context) {
    if (all.isEmpty) {
      return CmsStateCard(
        child: EmptyState(
          icon: Icons.local_offer_rounded,
          title: 'Belum ada promo',
          message: 'Tambahkan kode promo pertama untuk customer.',
          actionLabel: 'Tambah promo',
          onAction: onAdd,
        ),
      );
    }
    if (visible.isEmpty) {
      return CmsStateCard(
        child: EmptyState(
          icon: Icons.search_off_rounded,
          title: 'Promo tidak ditemukan',
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
                  final promo = visible[i];
                  final busy = manage.busyId == promo.id;
                  final phase = promoPhaseOf(promo);
                  return CmsItemTile(
                    leading: PromoDiscountBadge(promo: promo),
                    title: promo.title,
                    details: [
                      Wrap(
                        spacing: 6,
                        runSpacing: 4,
                        crossAxisAlignment: WrapCrossAlignment.center,
                        children: [
                          _CodePill(code: promo.code),
                          _Pill(text: phase.label, color: phase.color),
                        ],
                      ),
                      Text(
                        formatPromoPeriod(promo.startDate, promo.endDate),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: textTheme.bodySmall?.copyWith(
                          color: AppColors.onSurfaceVariant,
                        ),
                      ),
                    ],
                    isActive: busy
                        ? (manage.busyValue ?? promo.isActive)
                        : promo.isActive,
                    busy: busy,
                    inactiveLabel: 'Nonaktif · kode tidak bisa dipakai',
                    onTap: () => onTap(promo),
                    onToggle: (value) => onToggle(promo, value),
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

class _CodePill extends StatelessWidget {
  const _CodePill({required this.code});

  final String code;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppColors.outline.withValues(alpha: 0.5)),
      ),
      child: Text(
        code,
        style: Theme.of(context).textTheme.labelSmall?.copyWith(
          color: AppColors.onSurface,
          fontWeight: FontWeight.w700,
          letterSpacing: 0.6,
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
