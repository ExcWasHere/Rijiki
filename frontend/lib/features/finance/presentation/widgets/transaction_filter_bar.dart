import 'package:flutter/material.dart';
import 'package:rijiki/core/enums/expense_type.dart';
import 'package:rijiki/core/theme/app_colors.dart';
import 'package:rijiki/core/theme/app_spacing.dart';
import 'package:rijiki/features/finance/domain/transaction_filter.dart';
import 'package:rijiki/features/finance/presentation/expense_type_ui.dart';
import 'package:rijiki/features/finance/presentation/utils/finance_format.dart';

class TransactionFilterBar extends StatelessWidget {
  const TransactionFilterBar({
    super.key,
    required this.filter,
    required this.onTypeChanged,
    required this.onExpenseTypeChanged,
    required this.onPickRange,
    required this.onClearRange,
  });

  final TransactionFilter filter;
  final ValueChanged<TransactionTypeFilter> onTypeChanged;
  final ValueChanged<ExpenseType?> onExpenseTypeChanged;
  final VoidCallback onPickRange;
  final VoidCallback onClearRange;

  @override
  Widget build(BuildContext context) {
    final isExpense = filter.type == TransactionTypeFilter.expense;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _ChipRow(
          children: [
            for (final type in TransactionTypeFilter.values)
              _FilterChip(
                label: type.label,
                selected: filter.type == type,
                onTap: () => onTypeChanged(type),
              ),
          ],
        ),
        AnimatedSize(
          duration: const Duration(milliseconds: 220),
          curve: Curves.easeOutCubic,
          alignment: Alignment.topCenter,
          child: isExpense
              ? Padding(
                  padding: const EdgeInsets.only(top: AppSpacing.sm),
                  child: _ChipRow(
                    children: [
                      _FilterChip(
                        label: 'Semua tipe',
                        selected: filter.expenseType == null,
                        onTap: () => onExpenseTypeChanged(null),
                      ),
                      for (final type in ExpenseType.values)
                        _FilterChip(
                          label: type.label,
                          icon: type.icon,
                          accent: type.color,
                          selected: filter.expenseType == type,
                          onTap: () => onExpenseTypeChanged(type),
                        ),
                    ],
                  ),
                )
              : const SizedBox(width: double.infinity),
        ),
        const SizedBox(height: AppSpacing.sm),
        _DatePill(
          filter: filter,
          onPick: onPickRange,
          onClear: onClearRange,
        ),
      ],
    );
  }
}

class _ChipRow extends StatelessWidget {
  const _ChipRow({required this.children});

  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 38,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: children.length,
        separatorBuilder: (_, _) => const SizedBox(width: AppSpacing.sm),
        itemBuilder: (_, index) => children[index],
      ),
    );
  }
}

class _FilterChip extends StatelessWidget {
  const _FilterChip({
    required this.label,
    required this.selected,
    required this.onTap,
    this.icon,
    this.accent,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;
  final IconData? icon;
  final Color? accent;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final iconColor = accent ?? AppColors.primaryDark;

    return ChoiceChip(
      selected: selected,
      onSelected: (_) => onTap(),
      showCheckmark: false,
      avatar: icon == null ? null : Icon(icon, size: 16, color: iconColor),
      label: Text(label),
      labelStyle: textTheme.labelLarge?.copyWith(
        color: selected ? AppColors.onSurface : AppColors.onSurfaceVariant,
        fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
      ),
      backgroundColor: AppColors.surface,
      selectedColor: AppColors.primary.withValues(alpha: 0.3),
      shape: const StadiumBorder(),
      side: BorderSide(
        color: selected
            ? AppColors.primaryDark
            : AppColors.outline.withValues(alpha: 0.4),
      ),
    );
  }
}

class _DatePill extends StatelessWidget {
  const _DatePill({
    required this.filter,
    required this.onPick,
    required this.onClear,
  });

  final TransactionFilter filter;
  final VoidCallback onPick;
  final VoidCallback onClear;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final active = filter.hasRange;
    final label = active
        ? formatDateRange(filter.start!, filter.end!)
        : 'Semua tanggal';

    return Align(
      alignment: Alignment.centerLeft,
      child: Material(
        color: active
            ? AppColors.primary.withValues(alpha: 0.18)
            : AppColors.surface,
        shape: StadiumBorder(
          side: BorderSide(
            color: active
                ? AppColors.primaryDark
                : AppColors.outline.withValues(alpha: 0.4),
          ),
        ),
        child: InkWell(
          customBorder: const StadiumBorder(),
          onTap: onPick,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(12, 8, 12, 8),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(
                  Icons.calendar_month_rounded,
                  size: AppSpacing.iconSm,
                  color: AppColors.primaryDark,
                ),
                const SizedBox(width: 6),
                Text(
                  label,
                  style: textTheme.labelLarge?.copyWith(
                    color: AppColors.onSurface,
                  ),
                ),
                if (active) ...[
                  const SizedBox(width: 6),
                  GestureDetector(
                    behavior: HitTestBehavior.opaque,
                    onTap: onClear,
                    child: const Icon(
                      Icons.close_rounded,
                      size: AppSpacing.iconSm,
                      color: AppColors.onSurfaceVariant,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}
