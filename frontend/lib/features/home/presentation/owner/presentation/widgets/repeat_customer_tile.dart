import 'package:flutter/material.dart';
import 'package:rijiki/core/theme/app_colors.dart';
import 'package:rijiki/core/theme/app_spacing.dart';
import 'package:rijiki/core/utils/rupiah_formatter.dart';
import 'package:rijiki/features/home/presentation/owner/domain/repeat_customer.dart';

class RepeatCustomerTile extends StatelessWidget {
  const RepeatCustomerTile({super.key, required this.customer, this.rank});

  final RepeatCustomer customer;
  final int? rank;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final hasAvatar =
        customer.avatarUrl != null && customer.avatarUrl!.isNotEmpty;
    final initial = customer.name.isEmpty
        ? '?'
        : customer.name.characters.first.toUpperCase();

    return Padding(
      padding: const EdgeInsets.all(AppSpacing.md),
      child: Row(
        children: [
          SizedBox(
            width: 44,
            height: 44,
            child: Stack(
              clipBehavior: Clip.none,
              children: [
                Positioned.fill(
                  child: CircleAvatar(
                    backgroundColor: AppColors.primary.withValues(alpha: 0.25),
                    foregroundImage: hasAvatar
                        ? NetworkImage(customer.avatarUrl!)
                        : null,
                    child: Text(
                      initial,
                      style: textTheme.titleMedium?.copyWith(
                        color: AppColors.onPrimary,
                      ),
                    ),
                  ),
                ),
                if (rank != null)
                  Positioned(
                    right: -4,
                    bottom: -4,
                    child: Container(
                      width: 20,
                      height: 20,
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        color: AppColors.primaryDark,
                        shape: BoxShape.circle,
                        border: Border.all(color: AppColors.surface, width: 2),
                      ),
                      child: Text(
                        '$rank',
                        style: textTheme.labelSmall?.copyWith(
                          color: Colors.white,
                          fontSize: 10,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(width: AppSpacing.sm + 4),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  customer.name,
                  style: textTheme.titleSmall,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 2),
                Text(
                  '${customer.completedOrders} order selesai',
                  style: textTheme.bodySmall?.copyWith(
                    color: AppColors.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: AppSpacing.sm),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                RupiahFormatter.compact(customer.totalSpent),
                style: textTheme.titleSmall,
              ),
              const SizedBox(height: 2),
              Text(
                'total transaksi',
                style: textTheme.labelSmall?.copyWith(
                  color: AppColors.onSurfaceVariant,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
