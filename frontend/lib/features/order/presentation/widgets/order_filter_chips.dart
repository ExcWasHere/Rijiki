import 'package:flutter/material.dart';
import 'package:rijiki/core/theme/app_colors.dart';
import 'package:rijiki/core/theme/app_spacing.dart';
import 'package:rijiki/features/order/domain/order_filter.dart';

class OrderFilterChips extends StatelessWidget {
  const OrderFilterChips({
    super.key,
    required this.selected,
    required this.onSelected,
  });

  final OrderFilter selected;
  final ValueChanged<OrderFilter> onSelected;

  static String labelOf(OrderFilter filter) => switch (filter) {
        OrderFilter.all => 'Semua',
        OrderFilter.inProgress => 'Dalam perjalanan',
        OrderFilter.completed => 'Selesai',
        OrderFilter.cancelled => 'Dibatalkan',
      };

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 38,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
        itemCount: OrderFilter.values.length,
        separatorBuilder: (_, _) => const SizedBox(width: 8),
        itemBuilder: (context, index) {
          final filter = OrderFilter.values[index];
          return _FilterChip(
            label: labelOf(filter),
            selected: filter == selected,
            onTap: () => onSelected(filter),
          );
        },
      ),
    );
  }
}

class _FilterChip extends StatelessWidget {
  const _FilterChip({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        curve: Curves.easeOut,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: selected ? AppColors.primary : AppColors.surface,
          borderRadius: BorderRadius.circular(999),
          border: Border.all(
            color: selected
                ? AppColors.primary
                : AppColors.outline.withValues(alpha: 0.4),
          ),
        ),
        child: AnimatedDefaultTextStyle(
          duration: const Duration(milliseconds: 200),
          style: Theme.of(context).textTheme.labelLarge!.copyWith(
            color: selected ? AppColors.onPrimary : AppColors.onSurfaceVariant,
          ),
          child: Text(label),
        ),
      ),
    );
  }
}
