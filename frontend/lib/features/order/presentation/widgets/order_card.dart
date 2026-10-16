import 'package:flutter/material.dart';
import 'package:rijiki/core/enums/order_status.dart';
import 'package:rijiki/core/extensions/enum_ui_x.dart';
import 'package:rijiki/core/theme/app_colors.dart';
import 'package:rijiki/core/utils/currency_formatter.dart';
import 'package:rijiki/core/utils/date_formatter.dart';
import 'package:rijiki/features/order/domain/customer_order.dart';
import 'package:rijiki/features/order/presentation/widgets/order_progress_bar.dart';
import 'package:rijiki/features/order/presentation/widgets/payment_chip.dart';
import 'package:rijiki/shared/widgets/app_card.dart';
import 'package:rijiki/shared/widgets/status_chip.dart';

class OrderCard extends StatelessWidget {
  const OrderCard({super.key, required this.order, this.onTap});

  final CustomerOrder order;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final status = order.status;
    final muted = textTheme.bodySmall?.copyWith(
      color: AppColors.onSurfaceVariant,
    );
    final isCancelled = status == OrderStatus.cancelled;

    return AppCard(
      onTap: onTap,
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
                    Text(order.orderNumber, style: textTheme.titleSmall),
                    const SizedBox(height: 2),
                    Text(DateFormatter.shortDate(order.createdAt), style: muted),
                  ],
                ),
              ),
              StatusChip(
                label: status.label,
                color: status.color,
                icon: status.icon,
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            order.shoeNames,
            style: textTheme.titleSmall,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 2),
          Text(
            '${order.shoeCount} sepatu · ${order.serviceSummary}',
            style: muted,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          if (status.isActive) ...[
            const SizedBox(height: 14),
            OrderProgressBar(status: status),
            const SizedBox(height: 6),
            Text(status.hint, style: muted),
          ] else if (status == OrderStatus.completed &&
              order.completedAt != null) ...[
            const SizedBox(height: 8),
            Text(
              'Selesai ${DateFormatter.shortDate(order.completedAt!)}',
              style: muted,
            ),
          ],
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
              if (!isCancelled) PaymentChip(paid: order.isPaid),
            ],
          ),
        ],
      ),
    );
  }
}
