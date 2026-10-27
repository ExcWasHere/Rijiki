import 'package:flutter/material.dart';
import 'package:rijiki/core/extensions/enum_ui_x.dart';
import 'package:rijiki/core/theme/app_colors.dart';
import 'package:rijiki/core/utils/currency_formatter.dart';
import 'package:rijiki/core/utils/date_formatter.dart';
import 'package:rijiki/features/order/domain/customer_order.dart';
import 'package:rijiki/features/order/presentation/widgets/payment_chip.dart';
import 'package:rijiki/shared/widgets/app_card.dart';
import 'package:rijiki/shared/widgets/status_chip.dart';

class StaffOrderCard extends StatelessWidget {
  const StaffOrderCard({super.key, required this.order, this.onTap});

  final CustomerOrder order;
  final VoidCallback? onTap;

  String get _handler {
    if (order.assignedToMe) return 'Ditangani olehmu';
    final name = order.workerName;
    if (name != null && name.isNotEmpty) return 'Ditangani $name';
    return 'Belum diambil';
  }

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final muted = textTheme.bodySmall?.copyWith(
      color: AppColors.onSurfaceVariant,
    );
    final status = order.status;
    final unclaimed = order.assignedWorkerId == null && status.isActive;

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
            order.customerName ?? 'Customer',
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
          const SizedBox(height: 12),
          const Divider(),
          const SizedBox(height: 12),
          Row(
            children: [
              Icon(
                unclaimed
                    ? Icons.hourglass_empty_rounded
                    : Icons.person_outline_rounded,
                size: 16,
                color: unclaimed ? AppColors.warning : AppColors.onSurfaceVariant,
              ),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  _handler,
                  style: muted?.copyWith(
                    color: unclaimed ? AppColors.warning : null,
                    fontWeight: unclaimed ? FontWeight.w600 : null,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              Text(
                CurrencyFormatter.rupiah(order.totalPrice),
                style: textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w700),
              ),
              const SizedBox(width: 8),
              PaymentChip(paid: order.isPaid),
            ],
          ),
        ],
      ),
    );
  }
}
