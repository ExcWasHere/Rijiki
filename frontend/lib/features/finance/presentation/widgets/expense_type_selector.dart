import 'package:flutter/material.dart';
import 'package:rijiki/core/enums/expense_type.dart';
import 'package:rijiki/core/theme/app_colors.dart';
import 'package:rijiki/features/finance/presentation/expense_type_ui.dart';

class ExpenseTypeSelector extends StatelessWidget {
  const ExpenseTypeSelector({
    super.key,
    required this.selected,
    required this.onChanged,
  });

  final ExpenseType selected;
  final ValueChanged<ExpenseType> onChanged;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: [
        for (final type in ExpenseType.values)
          ChoiceChip(
            selected: type == selected,
            onSelected: (_) => onChanged(type),
            showCheckmark: false,
            avatar: Icon(type.icon, size: 16, color: type.color),
            label: Text(type.label),
            labelStyle: textTheme.labelLarge?.copyWith(
              color: type == selected
                  ? AppColors.onSurface
                  : AppColors.onSurfaceVariant,
              fontWeight: type == selected ? FontWeight.w700 : FontWeight.w500,
            ),
            backgroundColor: AppColors.surface,
            selectedColor: type.color.withValues(alpha: 0.16),
            shape: const StadiumBorder(),
            side: BorderSide(
              color: type == selected
                  ? type.color
                  : AppColors.outline.withValues(alpha: 0.4),
            ),
          ),
      ],
    );
  }
}
