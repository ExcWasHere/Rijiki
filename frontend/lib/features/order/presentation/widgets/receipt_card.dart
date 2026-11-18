import 'package:flutter/material.dart';
import 'package:rijiki/core/theme/app_colors.dart';
import 'package:rijiki/core/theme/app_spacing.dart';
import 'package:rijiki/core/utils/rupiah_formatter.dart';
import 'package:rijiki/core/utils/date_formatter.dart';
import 'package:rijiki/features/order/domain/customer_order.dart';
import 'package:rijiki/features/order/presentation/utils/discount_lines.dart';
import 'package:rijiki/shared/widgets/dashed_divider.dart';

class ReceiptCard extends StatelessWidget {
  const ReceiptCard({
    super.key,
    required this.order,
    required this.customerName,
    required this.customerPhone,
  });

  final CustomerOrder order;
  final String customerName;
  final String customerPhone;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final price = order.price;
    final muted = textTheme.bodySmall?.copyWith(
      color: AppColors.onSurfaceVariant,
    );

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
        border: Border.all(color: AppColors.outline.withValues(alpha: 0.28)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'RIJIKI SHOE CARE',
                      style: textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w800,
                        letterSpacing: 1.2,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text('Struk digital', style: muted),
                  ],
                ),
              ),
              if (order.isPaid) const _PaidStamp(),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          const DashedDivider(),
          const SizedBox(height: AppSpacing.md),
          _Line(label: 'No. order', value: order.orderNumber, bold: true),
          _Line(
            label: 'Tanggal',
            value: DateFormatter.dateTime(order.createdAt),
          ),
          _Line(label: 'Pemesan', value: customerName),
          _Line(label: 'No HP', value: customerPhone),
          if (order.workerName != null)
            _Line(label: 'Ditangani', value: order.workerName!),
          const SizedBox(height: AppSpacing.md),
          const DashedDivider(),
          const SizedBox(height: AppSpacing.md),
          for (final item in order.items) ...[
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        item.quantity > 1
                            ? '${item.shoeName} ×${item.quantity}'
                            : item.shoeName,
                        style: textTheme.titleSmall,
                      ),
                      Text(
                        item.quantity > 1
                            ? '${item.serviceName} · ${RupiahFormatter.full(item.price)}'
                            : item.serviceName,
                        style: muted,
                      ),
                    ],
                  ),
                ),
                Text(
                  RupiahFormatter.full(item.lineTotal),
                  style: textTheme.titleSmall,
                ),
              ],
            ),
            const SizedBox(height: 10),
          ],
          const SizedBox(height: 2),
          const DashedDivider(),
          const SizedBox(height: AppSpacing.md),
          _Line(
            label: 'Subtotal',
            value: RupiahFormatter.full(price.subtotal),
          ),
          for (final line in discountLines(price, order.promos))
            _Line(
              label: line.label,
              value: '-${RupiahFormatter.full(line.amount)}',
              valueColor: AppColors.success,
            ),
          _Line(label: 'Ongkir', value: RupiahFormatter.full(price.shipping)),
          const SizedBox(height: 6),
          Row(
            children: [
              Expanded(child: Text('TOTAL', style: textTheme.titleMedium)),
              Text(
                RupiahFormatter.full(price.total),
                style: textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.w800,
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          const _Line(label: 'Metode bayar', value: 'QRIS'),
          const SizedBox(height: AppSpacing.md),
          const DashedDivider(),
          const SizedBox(height: AppSpacing.md),
          Center(
            child: Text(
              'Terima kasih sudah mempercayakan sepatumu kepada Rijiki.\nSimpan struk ini sebagai bukti pembayaran.',
              textAlign: TextAlign.center,
              style: muted,
            ),
          ),
        ],
      ),
    );
  }
}

class _Line extends StatelessWidget {
  const _Line({
    required this.label,
    required this.value,
    this.bold = false,
    this.valueColor,
  });

  final String label;
  final String value;
  final bool bold;
  final Color? valueColor;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            flex: 2,
            child: Text(
              label,
              style: textTheme.bodyMedium?.copyWith(
                color: AppColors.onSurfaceVariant,
              ),
            ),
          ),
          Expanded(
            flex: 3,
            child: Text(
              value,
              textAlign: TextAlign.right,
              style: textTheme.bodyMedium?.copyWith(
                color: valueColor,
                fontWeight: bold ? FontWeight.w700 : FontWeight.w400,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _PaidStamp extends StatelessWidget {
  const _PaidStamp();

  @override
  Widget build(BuildContext context) {
    return Transform.rotate(
      angle: -0.12,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
        decoration: BoxDecoration(
          border: Border.all(color: AppColors.success, width: 2),
          borderRadius: BorderRadius.circular(6),
        ),
        child: Text(
          'LUNAS',
          style: Theme.of(context).textTheme.labelLarge?.copyWith(
            color: AppColors.success,
            fontWeight: FontWeight.w800,
            letterSpacing: 1.5,
          ),
        ),
      ),
    );
  }
}
