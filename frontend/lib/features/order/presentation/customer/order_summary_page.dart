import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:rijiki/app/router/route_paths.dart';
import 'package:rijiki/core/theme/app_colors.dart';
import 'package:rijiki/core/theme/app_spacing.dart';
import 'package:rijiki/features/order/domain/order_item.dart';
import 'package:rijiki/features/order/domain/price_quote.dart';
import 'package:rijiki/features/order/presentation/controllers/order_create_controller.dart';
import 'package:rijiki/features/order/presentation/widgets/order_item_tile.dart';
import 'package:rijiki/features/order/presentation/widgets/price_breakdown_card.dart';
import 'package:rijiki/shared/widgets/app_card.dart';
import 'package:rijiki/shared/widgets/error_state.dart';
import 'package:rijiki/shared/widgets/loading_skeleton.dart';
import 'package:rijiki/shared/widgets/section_header.dart';

class OrderSummaryPage extends ConsumerWidget {
  const OrderSummaryPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(orderCreateControllerProvider);
    final quote = ref.watch(orderQuoteProvider);
    final textTheme = Theme.of(context).textTheme;

    final items = [
      for (final item in state.items)
        OrderItem(
          id: item.id,
          shoeName: item.shoeBrand.trim(),
          serviceName: item.service?.name ?? '-',
          price: item.service?.basePrice ?? 0,
          quantity: item.quantity,
          notes: item.notes.trim().isEmpty ? null : item.notes.trim(),
        ),
    ];

    final readyQuote = quote.value;
    final canSubmit = readyQuote != null && !state.isSubmitting && state.isValid;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(title: const Text('Ringkasan order')),
      body: ListView(
        padding: const EdgeInsets.all(AppSpacing.lg),
        children: [
          const SectionHeader(title: 'Pemesan'),
          const SizedBox(height: AppSpacing.sm),
          AppCard(
            child: SizedBox(
              width: double.infinity,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(state.customerName.trim(), style: textTheme.titleSmall),
                  const SizedBox(height: 2),
                  Text(
                    state.phone.trim(),
                    style: textTheme.bodyMedium?.copyWith(
                      color: AppColors.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: AppSpacing.lg),
          const SectionHeader(title: 'Item'),
          const SizedBox(height: AppSpacing.sm),
          AppCard(
            child: Column(
              children: [
                for (var i = 0; i < items.length; i++) ...[
                  if (i > 0) ...[
                    const SizedBox(height: 12),
                    const Divider(),
                    const SizedBox(height: 12),
                  ],
                  OrderItemTile(item: items[i]),
                ],
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.lg),
          const SectionHeader(title: 'Alamat'),
          const SizedBox(height: AppSpacing.sm),
          AppCard(
            child: Column(
              children: [
                _AddressRow(
                  icon: Icons.upload_rounded,
                  label: 'Alamat penjemputan',
                  value: state.pickupAddress.trim(),
                ),
                const SizedBox(height: 12),
                _AddressRow(
                  icon: Icons.download_rounded,
                  label: 'Alamat pengantaran',
                  value: state.effectiveDeliveryAddress.trim(),
                ),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.lg),
          const SectionHeader(title: 'Rincian harga'),
          const SizedBox(height: AppSpacing.sm),
          quote.when(
            loading: () => const LoadingSkeleton(height: 170),
            error: (error, _) => AppCard(
              child: SizedBox(
                width: double.infinity,
                child: error is PromoException
                    ? ErrorState(
                        message: error.message,
                        onRetry: () {
                          ref
                              .read(orderCreateControllerProvider.notifier)
                              .clearPromo();
                        },
                      )
                    : ErrorState(
                        message: 'Harga gagal dihitung. Coba lagi ya.',
                        onRetry: () => ref.invalidate(orderQuoteProvider),
                      ),
              ),
            ),
            data: (data) => PriceBreakdownCard(
              price: data.price,
              paid: false,
              promoCode: data.promoCode,
              showPaymentStatus: false,
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Icon(
                Icons.info_outline_rounded,
                size: 18,
                color: AppColors.onSurfaceVariant,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Harga layanan tetap dan tidak berubah setelah sepatu dicek.',
                  style: textTheme.bodySmall?.copyWith(
                    color: AppColors.onSurfaceVariant,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
      bottomNavigationBar: DecoratedBox(
        decoration: BoxDecoration(
          color: AppColors.surface,
          border: Border(
            top: BorderSide(color: AppColors.outline.withValues(alpha: 0.25)),
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.md),
          child: FilledButton(
            onPressed: canSubmit ? () => _submit(context, ref, readyQuote!) : null,
            child: state.isSubmitting
                ? const SizedBox(
                    width: 22,
                    height: 22,
                    child: CircularProgressIndicator(
                      strokeWidth: 2.4,
                      color: AppColors.onPrimary,
                    ),
                  )
                : const Text('Buat order & bayar'),
          ),
        ),
      ),
    );
  }

  Future<void> _submit(
    BuildContext context,
    WidgetRef ref,
    PriceQuote quote,
  ) async {
    final order = await ref
        .read(orderCreateControllerProvider.notifier)
        .submit(quote);
    if (!context.mounted) return;

    if (order == null) {
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(
          const SnackBar(content: Text('Order gagal dibuat. Coba lagi ya.')),
        );
      return;
    }
    context.go(RoutePaths.orderPaymentFor(order.id));
  }
}

class _AddressRow extends StatelessWidget {
  const _AddressRow({
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
