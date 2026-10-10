import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:rijiki/app/router/route_paths.dart';
import 'package:rijiki/core/enums/order_status.dart';
import 'package:rijiki/core/extensions/enum_ui_x.dart';
import 'package:rijiki/core/theme/app_colors.dart';
import 'package:rijiki/core/theme/app_spacing.dart';
import 'package:rijiki/features/order/domain/customer_order.dart';
import 'package:rijiki/features/order/presentation/controllers/order_detail_controller.dart';
import 'package:rijiki/features/order/presentation/widgets/order_status_stepper.dart';
import 'package:rijiki/shared/widgets/app_card.dart';
import 'package:rijiki/shared/widgets/error_state.dart';
import 'package:rijiki/shared/widgets/loading_skeleton.dart';

class OrderTrackingPage extends ConsumerWidget {
  const OrderTrackingPage({super.key, required this.orderId});

  final String orderId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final order = ref.watch(orderDetailProvider(orderId));

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(title: const Text('Lacak order')),
      body: order.when(
        loading: () => ListView(
          padding: const EdgeInsets.all(AppSpacing.lg),
          children: const [
            LoadingSkeleton(height: 96),
            SizedBox(height: AppSpacing.lg),
            LoadingSkeleton(height: 300),
          ],
        ),
        error: (_, _) => Center(
          child: ErrorState(
            message: 'Status order gagal dimuat. Coba lagi ya.',
            onRetry: () => ref.invalidate(orderDetailProvider(orderId)),
          ),
        ),
        data: (data) => _TrackingBody(order: data),
      ),
    );
  }
}

class _TrackingBody extends StatelessWidget {
  const _TrackingBody({required this.order});

  final CustomerOrder order;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final status = order.status;

    return ListView(
      padding: const EdgeInsets.all(AppSpacing.lg),
      children: [
        Container(
          padding: const EdgeInsets.all(AppSpacing.md),
          decoration: BoxDecoration(
            color: status.color.withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
          ),
          child: Row(
            children: [
              Icon(status.icon, size: 30, color: status.color),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(order.orderNumber, style: textTheme.bodySmall),
                    const SizedBox(height: 2),
                    Text(status.label, style: textTheme.titleMedium),
                    const SizedBox(height: 2),
                    Text(status.hint, style: textTheme.bodyMedium),
                  ],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: AppSpacing.lg),
        if (status == OrderStatus.delivery) ...[
          AppCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Icon(
                      Icons.local_shipping_rounded,
                      color: AppColors.rijikiOrange,
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        'Kurir sedang mengantar sepatumu',
                        style: textTheme.titleSmall,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                OutlinedButton.icon(
                  onPressed: () =>
                      context.push(RoutePaths.deliveryMapFor(order.id)),
                  icon: const Icon(Icons.map_outlined, size: 20),
                  label: const Text('Lihat posisi kurir'),
                ),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.lg),
        ],
        Text('Riwayat status', style: textTheme.titleMedium),
        const SizedBox(height: AppSpacing.md),
        OrderStatusStepper(order: order),
      ],
    );
  }
}
