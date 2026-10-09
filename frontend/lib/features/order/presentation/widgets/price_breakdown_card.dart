import 'package:flutter/material.dart';
import 'package:rijiki/core/theme/app_colors.dart';
import 'package:rijiki/core/utils/currency_formatter.dart';
import 'package:rijiki/features/order/domain/price_breakdown.dart';
import 'package:rijiki/features/order/presentation/widgets/payment_chip.dart';
import 'package:rijiki/shared/widgets/app_card.dart';

class PriceBreakdownCard extends StatelessWidget {
  const PriceBreakdownCard({
    super.key,
    required this.price,
    required this.paid,
    this.promoCode,
    this.showPaymentStatus = true,
  });

  final PriceBreakdown price;
  final bool paid;
  final String? promoCode;
  final bool showPaymentStatus;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return AppCard(
      child: Column(
        children: [
          _Row(label: 'Subtotal layanan', value: CurrencyFormatter.rupiah(price.subtotal)),
          if (price.discount > 0) ...[
            const SizedBox(height: 8),
            _Row(
              label: promoCode == null ? 'Diskon' : 'Diskon ($promoCode)',
              value: '-${CurrencyFormatter.rupiah(price.discount)}',
              valueColor: AppColors.success,
            ),
          ],
          const SizedBox(height: 8),
          _Row(label: 'Ongkir', value: CurrencyFormatter.rupiah(price.shipping)),
          const SizedBox(height: 12),
          const Divider(),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(child: Text('Total', style: textTheme.titleSmall)),
              Text(
                CurrencyFormatter.rupiah(price.total),
                style: textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
          if (showPaymentStatus) ...[
            const SizedBox(height: 10),
            Align(
              alignment: Alignment.centerRight,
              child: PaymentChip(paid: paid),
            ),
          ],
        ],
      ),
    );
  }
}

class _Row extends StatelessWidget {
  const _Row({required this.label, required this.value, this.valueColor});

  final String label;
  final String value;
  final Color? valueColor;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return Row(
      children: [
        Expanded(
          child: Text(
            label,
            style: textTheme.bodyMedium?.copyWith(
              color: AppColors.onSurfaceVariant,
            ),
          ),
        ),
        Text(value, style: textTheme.bodyMedium?.copyWith(color: valueColor)),
      ],
    );
  }
}
