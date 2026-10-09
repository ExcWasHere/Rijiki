import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:rijiki/app/router/route_paths.dart';
import 'package:rijiki/core/enums/order_status.dart';
import 'package:rijiki/core/extensions/enum_ui_x.dart';
import 'package:rijiki/core/theme/app_colors.dart';
import 'package:rijiki/core/theme/app_spacing.dart';
import 'package:rijiki/core/utils/currency_formatter.dart';
import 'package:rijiki/core/utils/date_formatter.dart';
import 'package:rijiki/features/order/domain/customer_order.dart';
import 'package:rijiki/features/order/presentation/controllers/order_detail_controller.dart';
import 'package:rijiki/features/order/presentation/widgets/before_after_gallery.dart';
import 'package:rijiki/features/order/presentation/widgets/order_item_tile.dart';
import 'package:rijiki/features/order/presentation/widgets/order_progress_bar.dart';
import 'package:rijiki/features/order/presentation/widgets/price_breakdown_card.dart';
import 'package:rijiki/shared/widgets/app_card.dart';
import 'package:rijiki/shared/widgets/error_state.dart';
import 'package:rijiki/shared/widgets/loading_skeleton.dart';
import 'package:rijiki/shared/widgets/section_header.dart';
import 'package:rijiki/shared/widgets/status_chip.dart';

void _comingSoon(BuildContext context, String message) {
  ScaffoldMessenger.of(context)
    ..hideCurrentSnackBar()
    ..showSnackBar(SnackBar(content: Text(message)));
}

class OrderDetailPage extends ConsumerWidget {
  const OrderDetailPage({super.key, required this.orderId});

  final String orderId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final order = ref.watch(orderDetailProvider(orderId));
    final loaded = order.value;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(title: const Text('Detail order')),
      body: order.when(
        loading: () => ListView(
          padding: const EdgeInsets.all(AppSpacing.lg),
          children: const [
            LoadingSkeleton(height: 150),
            SizedBox(height: AppSpacing.md),
            LoadingSkeleton(height: 170),
            SizedBox(height: AppSpacing.md),
            LoadingSkeleton(height: 130),
          ],
        ),
        error: (_, _) => Center(
          child: ErrorState(
            message: 'Order gagal dimuat. Coba lagi ya.',
            onRetry: () => ref.invalidate(orderDetailProvider(orderId)),
          ),
        ),
        data: (data) => _DetailBody(order: data),
      ),
      bottomNavigationBar: loaded == null ? null : _ActionBar(order: loaded),
    );
  }
}

class _DetailBody extends StatelessWidget {
  const _DetailBody({required this.order});

  final CustomerOrder order;

  bool get _showGallery =>
      order.status != OrderStatus.cancelled && order.status.progressStep >= 3;

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(AppSpacing.lg),
      children: [
        _HeaderCard(order: order),
        const SizedBox(height: AppSpacing.lg),
        const SectionHeader(title: 'Item'),
        const SizedBox(height: AppSpacing.sm),
        AppCard(
          child: Column(
            children: [
              for (var i = 0; i < order.items.length; i++) ...[
                if (i > 0) ...[
                  const SizedBox(height: 12),
                  const Divider(),
                  const SizedBox(height: 12),
                ],
                OrderItemTile(item: order.items[i]),
              ],
            ],
          ),
        ),
        const SizedBox(height: AppSpacing.lg),
        const SectionHeader(title: 'Penjemputan & pengantaran'),
        const SizedBox(height: AppSpacing.sm),
        AppCard(
          child: Column(
            children: [
              _InfoRow(
                icon: Icons.upload_rounded,
                label: 'Alamat penjemputan',
                value: order.pickupAddress,
              ),
              const SizedBox(height: 12),
              _InfoRow(
                icon: Icons.download_rounded,
                label: 'Alamat pengantaran',
                value: order.deliveryAddress,
              ),
              if (order.scheduledPickupAt != null) ...[
                const SizedBox(height: 12),
                _InfoRow(
                  icon: Icons.schedule_rounded,
                  label: 'Jadwal jemput',
                  value: DateFormatter.dateTime(order.scheduledPickupAt!),
                ),
              ],
              if (order.workerName != null) ...[
                const SizedBox(height: 12),
                _InfoRow(
                  icon: Icons.person_outline_rounded,
                  label: 'Ditangani oleh',
                  value: order.workerName!,
                ),
              ],
            ],
          ),
        ),
        const SizedBox(height: AppSpacing.lg),
        const SectionHeader(title: 'Pembayaran'),
        const SizedBox(height: AppSpacing.sm),
        PriceBreakdownCard(
          price: order.price,
          paid: order.isPaid,
          promoCode: order.promoCode,
          showPaymentStatus: order.status != OrderStatus.cancelled,
        ),
        if (order.isPaid)
          Align(
            alignment: Alignment.centerLeft,
            child: TextButton.icon(
              onPressed: () =>
                  _comingSoon(context, 'Struk digital segera hadir.'),
              icon: const Icon(Icons.receipt_outlined, size: 18),
              label: const Text('Lihat struk digital'),
            ),
          ),
        if (_showGallery) ...[
          const SizedBox(height: AppSpacing.lg),
          const SectionHeader(title: 'Foto sebelum & sesudah'),
          const SizedBox(height: AppSpacing.sm),
          BeforeAfterGallery(
            items: order.items,
            documentation: order.documentation,
          ),
        ],
      ],
    );
  }
}

class _HeaderCard extends StatelessWidget {
  const _HeaderCard({required this.order});

  final CustomerOrder order;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final status = order.status;
    final muted = textTheme.bodySmall?.copyWith(
      color: AppColors.onSurfaceVariant,
    );

    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(order.orderNumber, style: textTheme.titleMedium),
              ),
              StatusChip(
                label: status.label,
                color: status.color,
                icon: status.icon,
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text('Dibuat ${DateFormatter.dateTime(order.createdAt)}', style: muted),
          if (status.isActive) ...[
            const SizedBox(height: 14),
            OrderProgressBar(status: status),
          ],
          const SizedBox(height: 8),
          Text(status.hint, style: textTheme.bodyMedium),
          if (status == OrderStatus.completed && order.completedAt != null) ...[
            const SizedBox(height: 2),
            Text(
              'Selesai ${DateFormatter.dateTime(order.completedAt!)}',
              style: muted,
            ),
          ],
          const SizedBox(height: 14),
          OutlinedButton.icon(
            onPressed: () =>
                context.push(RoutePaths.orderTrackingFor(order.id)),
            icon: const Icon(Icons.timeline_rounded, size: 20),
            label: Text(
              status == OrderStatus.cancelled
                  ? 'Lihat riwayat status'
                  : 'Lacak order',
            ),
          ),
        ],
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  const _InfoRow({
    required this.icon,
    required this.label,
    required this.value,
  });

  final IconData icon;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 18, color: AppColors.onSurfaceVariant),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: textTheme.bodySmall?.copyWith(
                  color: AppColors.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: 2),
              Text(value, style: textTheme.bodyMedium),
            ],
          ),
        ),
      ],
    );
  }
}

class _ActionBar extends StatelessWidget {
  const _ActionBar({required this.order});

  final CustomerOrder order;

  @override
  Widget build(BuildContext context) {
    final String label;
    final String message;
    if (order.canPay) {
      label = 'Bayar ${CurrencyFormatter.rupiah(order.totalPrice)}';
      message = '';
    } else if (order.canRate) {
      label = 'Beri rating';
      message = 'Fitur rating segera hadir.';
    } else {
      return const SizedBox.shrink();
    }

    return DecoratedBox(
      decoration: BoxDecoration(
        color: AppColors.surface,
        border: Border(
          top: BorderSide(color: AppColors.outline.withValues(alpha: 0.25)),
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: FilledButton(
          // TODO: halaman rating menyusul.
          onPressed: order.canPay
              ? () => context.push(RoutePaths.orderPaymentFor(order.id))
              : () => _comingSoon(context, message),
          child: Text(label),
        ),
      ),
    );
  }
}
