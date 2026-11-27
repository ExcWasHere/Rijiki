import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:rijiki/app/router/route_paths.dart';
import 'package:rijiki/core/theme/app_colors.dart';
import 'package:rijiki/core/theme/app_spacing.dart';
import 'package:rijiki/features/points/presentation/controllers/point_management_controller.dart';

/// Pintu masuk poin untuk owner dan worker berizin `manage_points`.
class PointsHubPage extends ConsumerWidget {
  const PointsHubPage({super.key});

  Future<void> _open(BuildContext context, WidgetRef ref, String route) async {
    await context.push(route);
    if (!context.mounted) return;
    ref.invalidate(pendingRedemptionCountProvider);
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final textTheme = Theme.of(context).textTheme;
    final pending = ref.watch(pendingRedemptionCountProvider).value ?? 0;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(title: const Text('Poin')),
      body: RefreshIndicator(
        color: AppColors.primaryDark,
        onRefresh: () async {
          ref.invalidate(pendingRedemptionCountProvider);
          try {
            await ref.read(pendingRedemptionCountProvider.future);
          } catch (_) {}
        },
        child: ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.fromLTRB(
            AppSpacing.lg,
            AppSpacing.md,
            AppSpacing.lg,
            AppSpacing.xl,
          ),
          children: [
            Text(
              'Proses penukaran poin, koreksi saldo customer, dan atur '
              'berapa poin yang didapat.',
              style: textTheme.bodyMedium?.copyWith(
                color: AppColors.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: AppSpacing.md),
            Container(
              clipBehavior: Clip.antiAlias,
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
                border: Border.all(
                  color: AppColors.outline.withValues(alpha: 0.3),
                ),
              ),
              child: Material(
                color: AppColors.surface,
                child: Column(
                  children: [
                    _HubTile(
                      icon: Icons.redeem_rounded,
                      color: AppColors.rijikiOrange,
                      title: 'Penukaran poin',
                      subtitle: pending > 0
                          ? '$pending pengajuan menunggu persetujuan'
                          : 'Setujui atau tolak pengajuan tukar poin',
                      badge: pending,
                      onTap: () => _open(
                        context,
                        ref,
                        RoutePaths.managementPointRedemptions,
                      ),
                    ),
                    _divider(),
                    _HubTile(
                      icon: Icons.tune_rounded,
                      color: AppColors.rijikiBlue,
                      title: 'Sesuaikan poin',
                      subtitle: 'Tambah atau kurangi saldo poin customer',
                      onTap: () =>
                          _open(context, ref, RoutePaths.managementPointAdjust),
                    ),
                    _divider(),
                    _HubTile(
                      icon: Icons.stars_rounded,
                      color: AppColors.primaryDark,
                      title: 'Aturan poin',
                      subtitle: 'Jumlah poin dari order selesai dan rating',
                      onTap: () =>
                          _open(context, ref, RoutePaths.ownerCmsPoints),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _divider() => Divider(
    height: 1,
    indent: AppSpacing.md,
    endIndent: AppSpacing.md,
    color: AppColors.outline.withValues(alpha: 0.2),
  );
}

class _HubTile extends StatelessWidget {
  const _HubTile({
    required this.icon,
    required this.color,
    required this.title,
    required this.subtitle,
    required this.onTap,
    this.badge = 0,
  });

  final IconData icon;
  final Color color;
  final String title;
  final String subtitle;
  final int badge;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Row(
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.14),
                borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
              ),
              child: Icon(icon, color: color),
            ),
            const SizedBox(width: AppSpacing.md),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: textTheme.titleSmall),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: textTheme.bodySmall?.copyWith(
                      color: AppColors.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),
            if (badge > 0) ...[
              const SizedBox(width: AppSpacing.sm),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: AppColors.rijikiOrange,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  badge > 99 ? '99+' : '$badge',
                  style: textTheme.labelSmall?.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
            ],
            const SizedBox(width: 4),
            const Icon(
              Icons.chevron_right_rounded,
              color: AppColors.onSurfaceVariant,
            ),
          ],
        ),
      ),
    );
  }
}
