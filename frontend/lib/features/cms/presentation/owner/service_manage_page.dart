import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:rijiki/app/router/route_paths.dart';
import 'package:rijiki/core/theme/app_colors.dart';
import 'package:rijiki/core/theme/app_spacing.dart';
import 'package:rijiki/features/cms/presentation/controllers/service_manage_controller.dart';
import 'package:rijiki/features/cms/presentation/widgets/cms_state_card.dart';
import 'package:rijiki/features/cms/presentation/widgets/service_filter_bar.dart';
import 'package:rijiki/features/cms/presentation/widgets/service_manage_tile.dart';
import 'package:rijiki/features/service/domain/care_service.dart';
import 'package:rijiki/shared/widgets/empty_state.dart';
import 'package:rijiki/shared/widgets/error_state.dart';
import 'package:rijiki/shared/widgets/loading_skeleton.dart';

class ServiceManagePage extends ConsumerStatefulWidget {
  const ServiceManagePage({super.key});

  @override
  ConsumerState<ServiceManagePage> createState() => _ServiceManagePageState();
}

class _ServiceManagePageState extends ConsumerState<ServiceManagePage> {
  final TextEditingController _search = TextEditingController();

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  Future<void> _toggle(CareService service, bool active) async {
    final messenger = ScaffoldMessenger.of(context);

    if (!active) {
      final confirmed = await showDialog<bool>(
        context: context,
        builder: (dialogContext) => AlertDialog(
          title: Text('Nonaktifkan ${service.name}?'),
          content: const Text(
            'Layanan tidak akan tampil lagi di aplikasi customer. '
            'Order yang sudah ada tidak terpengaruh, dan layanan bisa '
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
        .read(serviceManageProvider.notifier)
        .setActive(service, active);
    if (!mounted) return;

    final message = ok
        ? '${service.name} ${active ? 'diaktifkan' : 'dinonaktifkan'}.'
        : (ref.read(serviceManageProvider).errorMessage ??
              'Gagal mengubah status.');
    messenger
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  Widget build(BuildContext context) {
    final async = ref.watch(cmsServicesProvider);
    final all = async.value;
    final filter = ref.watch(serviceManageFilterProvider);
    final counts = ref.watch(cmsServiceCountsProvider);
    final visible = ref.watch(filteredCmsServicesProvider);
    final manage = ref.watch(serviceManageProvider);
    final notifier = ref.read(serviceManageFilterProvider.notifier);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(title: const Text('Layanan')),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => context.push(RoutePaths.ownerCmsServiceNew),
        backgroundColor: AppColors.primary,
        foregroundColor: AppColors.onPrimary,
        icon: const Icon(Icons.add_rounded),
        label: const Text('Tambah layanan'),
      ),
      body: RefreshIndicator(
        color: AppColors.primaryDark,
        onRefresh: () async {
          ref.invalidate(cmsServicesProvider);
          try {
            await ref.read(cmsServicesProvider.future);
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
            ServiceFilterBar(
              controller: _search,
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
                  onTap: (service) => context.push(
                    RoutePaths.ownerCmsServiceEditFor(service.id),
                  ),
                  onToggle: _toggle,
                  onAdd: () => context.push(RoutePaths.ownerCmsServiceNew),
                  onReset: () {
                    _search.clear();
                    notifier.reset();
                  },
                ),
              )
            else if (async.hasError)
              CmsStateCard(
                child: ErrorState(
                  message: 'Gagal memuat layanan.',
                  onRetry: () => ref.invalidate(cmsServicesProvider),
                ),
              )
            else
              const _ListSkeleton(),
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

  final List<CareService> all;
  final List<CareService> visible;
  final ServiceManageState manage;
  final ValueChanged<CareService> onTap;
  final Future<void> Function(CareService service, bool active) onToggle;
  final VoidCallback onAdd;
  final VoidCallback onReset;

  @override
  Widget build(BuildContext context) {
    if (all.isEmpty) {
      return CmsStateCard(
        child: EmptyState(
          icon: Icons.cleaning_services_rounded,
          title: 'Belum ada layanan',
          message: 'Tambahkan layanan pertama untuk ditawarkan ke customer.',
          actionLabel: 'Tambah layanan',
          onAction: onAdd,
        ),
      );
    }
    if (visible.isEmpty) {
      return CmsStateCard(
        child: EmptyState(
          icon: Icons.search_off_rounded,
          title: 'Layanan tidak ditemukan',
          actionLabel: 'Reset pencarian',
          onAction: onReset,
        ),
      );
    }

    final textTheme = Theme.of(context).textTheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        for (final category in ServiceCategory.values)
          if (visible.any((s) => s.category == category)) ...[
            Padding(
              padding: const EdgeInsets.only(
                left: AppSpacing.xs,
                bottom: AppSpacing.sm,
              ),
              child: Text(
                category.label,
                style: textTheme.labelLarge?.copyWith(
                  color: AppColors.onSurfaceVariant,
                ),
              ),
            ),
            _CategoryCard(
              services: [
                for (final s in visible)
                  if (s.category == category) s,
              ],
              manage: manage,
              onTap: onTap,
              onToggle: onToggle,
            ),
            const SizedBox(height: AppSpacing.md),
          ],
      ],
    );
  }
}

class _CategoryCard extends StatelessWidget {
  const _CategoryCard({
    required this.services,
    required this.manage,
    required this.onTap,
    required this.onToggle,
  });

  final List<CareService> services;
  final ServiceManageState manage;
  final ValueChanged<CareService> onTap;
  final Future<void> Function(CareService service, bool active) onToggle;

  @override
  Widget build(BuildContext context) {
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
            for (var i = 0; i < services.length; i++) ...[
              if (i > 0)
                Divider(
                  height: 1,
                  indent: AppSpacing.md,
                  endIndent: AppSpacing.md,
                  color: AppColors.outline.withValues(alpha: 0.2),
                ),
              Builder(
                builder: (context) {
                  final service = services[i];
                  final busy = manage.busyId == service.id;
                  return ServiceManageTile(
                    service: service,
                    isActive: busy ? (manage.busyValue ?? service.isActive) : service.isActive,
                    busy: busy,
                    onTap: () => onTap(service),
                    onToggle: (value) => onToggle(service, value),
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

class _ListSkeleton extends StatelessWidget {
  const _ListSkeleton();

  @override
  Widget build(BuildContext context) {
    const radius = AppSpacing.radiusLg;
    return const Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        LoadingSkeleton(height: 280, radius: radius),
        SizedBox(height: AppSpacing.md),
        LoadingSkeleton(height: 320, radius: radius),
      ],
    );
  }
}
