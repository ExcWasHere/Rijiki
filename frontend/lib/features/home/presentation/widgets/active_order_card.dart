import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:rijiki/app/router/route_paths.dart';
import 'package:rijiki/core/enums/order_payment_status.dart';
import 'package:rijiki/core/extensions/enum_ui_x.dart';
import 'package:rijiki/core/theme/app_colors.dart';
import 'package:rijiki/core/theme/app_spacing.dart';
import 'package:rijiki/core/utils/currency_formatter.dart';
import 'package:rijiki/features/home/presentation/controllers/home_controller.dart';
import 'package:rijiki/features/order/domain/customer_order.dart';
import 'package:rijiki/features/order/presentation/widgets/order_progress_bar.dart';
import 'package:rijiki/shared/widgets/app_card.dart';
import 'package:rijiki/shared/widgets/empty_state.dart';
import 'package:rijiki/shared/widgets/error_state.dart';
import 'package:rijiki/shared/widgets/loading_skeleton.dart';
import 'package:rijiki/shared/widgets/section_header.dart';
import 'package:rijiki/shared/widgets/state_card.dart';
import 'package:rijiki/shared/widgets/status_chip.dart';

class ActiveOrderSection extends ConsumerWidget {
  const ActiveOrderSection({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final orders = ref.watch(homeActiveOrdersProvider);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SectionHeader(
            title: 'Order aktif',
            onAction: () => context.go(RoutePaths.customerOrders),
          ),
          const SizedBox(height: AppSpacing.sm),
          orders.when(
            loading: () => const LoadingSkeleton(height: 168),
            error: (_, _) => StateCard(
              child: ErrorState(
                onRetry: () => ref.invalidate(homeActiveOrdersProvider),
              ),
            ),
            data: (list) {
              if (list.isEmpty) {
                return StateCard(
                  child: EmptyState(
                    icon: Icons.inventory_2_outlined,
                    title: 'Belum ada order aktif',
                    message: 'Order yang sedang berjalan akan muncul di sini.',
                    actionLabel: 'Mulai order',
                    onAction: () => context.go(RoutePaths.customerOrders),
                  ),
                );
              }
              return Column(
                children: [
                  for (var i = 0; i < list.length; i++) ...[
                    if (i > 0) const SizedBox(height: 12),
                    ActiveOrderCard(
                      order: list[i],
                      onTap: () => context.go(
                        RoutePaths.orderDetailFor(list[i].id),
                      ),
                    ),
                  ],
                ],
              );
            },
          ),
        ],
      ),
    );
  }
}

class ActiveOrderCard extends StatelessWidget {
  const ActiveOrderCard({super.key, required this.order, this.onTap});

  final CustomerOrder order;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final status = order.status;
    final isPaid = order.paymentStatus == OrderPaymentStatus.paid;

    return AppCard(
      onTap: onTap,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  order.orderNumber,
                  style: textTheme.titleSmall,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              StatusChip(
                label: status.label,
                color: status.color,
                icon: status.icon,
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            '${order.shoeCount} sepatu · ${order.serviceSummary}',
            style: textTheme.bodyMedium?.copyWith(
              color: AppColors.onSurfaceVariant,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 14),
          OrderProgressBar(status: status),
          const SizedBox(height: 8),
          Text(
            status.hint,
            style: textTheme.bodySmall?.copyWith(
              color: AppColors.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 12),
          const Divider(),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: Text(
                  CurrencyFormatter.rupiah(order.totalPrice),
                  style: textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              StatusChip(
                label: isPaid ? 'Lunas' : 'Belum dibayar',
                color: isPaid ? AppColors.success : AppColors.warning,
              ),
            ],
          ),
        ],
      ),
    );
  }
}
