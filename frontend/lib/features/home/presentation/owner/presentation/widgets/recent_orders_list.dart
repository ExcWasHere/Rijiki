import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:rijiki/core/enums/order_status.dart';
import 'package:rijiki/core/extensions/enum_ui_x.dart';
import 'package:rijiki/core/theme/app_colors.dart';
import 'package:rijiki/core/theme/app_spacing.dart';
import 'package:rijiki/core/utils/rupiah_formatter.dart';
import 'package:rijiki/features/home/presentation/owner/domain/recent_order.dart';
import 'package:rijiki/features/home/presentation/owner/presentation/controllers/dashboard_controller.dart';
import 'package:rijiki/features/home/presentation/owner/presentation/widgets/dashboard_message_card.dart';
import 'package:rijiki/features/home/presentation/owner/presentation/widgets/dashboard_section_header.dart';
import 'package:rijiki/features/home/presentation/owner/presentation/widgets/skeleton_block.dart';

class RecentOrdersSection extends ConsumerWidget {
  const RecentOrdersSection({super.key, this.onSeeAll});

  final VoidCallback? onSeeAll;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(dashboardRecentOrdersProvider);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        DashboardSectionHeader(
          title: 'Order terbaru',
          actionLabel: 'Lihat semua',
          onAction: onSeeAll,
        ),
        const SizedBox(height: AppSpacing.sm + 4),
        async.when(
          data: (orders) => orders.isEmpty
              ? const DashboardMessageCard(
                  icon: Icons.receipt_long_outlined,
                  message: 'Belum ada order masuk.',
                )
              : _OrderCard(orders: orders),
          loading: () => const SkeletonBlock(height: 300),
          error: (error, stackTrace) => DashboardMessageCard(
            icon: Icons.cloud_off_rounded,
            message: 'Gagal memuat order terbaru.',
            actionLabel: 'Coba lagi',
            onAction: () => ref.invalidate(dashboardRecentOrdersProvider),
          ),
        ),
      ],
    );
  }
}

class _OrderCard extends StatelessWidget {
  const _OrderCard({required this.orders});

  final List<RecentOrder> orders;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
        border: Border.all(color: AppColors.outline.withValues(alpha: 0.3)),
      ),
      child: Column(
        children: [
          for (var i = 0; i < orders.length; i++) ...[
            if (i > 0)
              Divider(
                height: 1,
                indent: AppSpacing.md,
                endIndent: AppSpacing.md,
                color: AppColors.outline.withValues(alpha: 0.2),
              ),
            _OrderTile(order: orders[i]),
          ],
        ],
      ),
    );
  }
}

class _OrderTile extends StatelessWidget {
  const _OrderTile({required this.order});

  final RecentOrder order;

  static Color _statusColor(OrderStatus status) => switch (status) {
    OrderStatus.order => AppColors.info,
    OrderStatus.pickup => AppColors.rijikiOrange,
    OrderStatus.waiting => AppColors.warning,
    OrderStatus.cleaning => AppColors.primaryDark,
    OrderStatus.delivery => AppColors.rijikiBlue,
    OrderStatus.completed => AppColors.success,
    OrderStatus.cancelled => AppColors.error,
  };

  static String _timeAgo(DateTime time) {
    final diff = DateTime.now().difference(time);
    if (diff.inMinutes < 1) return 'Baru saja';
    if (diff.inMinutes < 60) return '${diff.inMinutes} mnt lalu';
    if (diff.inHours < 24) return '${diff.inHours} jam lalu';
    if (diff.inDays == 1) return 'Kemarin';
    return '${diff.inDays} hari lalu';
  }

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final color = _statusColor(order.status);

    return Padding(
      padding: const EdgeInsets.all(AppSpacing.md),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.14),
              borderRadius: BorderRadius.circular(AppSpacing.radiusMd - 2),
            ),
            child: Icon(order.status.icon, size: 20, color: color),
          ),
          const SizedBox(width: AppSpacing.sm + 4),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  order.customerName,
                  style: textTheme.titleSmall,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 2),
                Text(
                  '${order.itemCount} sepatu · ${_timeAgo(order.createdAt)}',
                  style: textTheme.bodySmall?.copyWith(
                    color: AppColors.onSurfaceVariant,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          const SizedBox(width: AppSpacing.sm),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                RupiahFormatter.full(order.total),
                style: textTheme.titleSmall,
              ),
              const SizedBox(height: 4),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.14),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  order.status.label,
                  style: textTheme.labelSmall?.copyWith(
                    color: color,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
