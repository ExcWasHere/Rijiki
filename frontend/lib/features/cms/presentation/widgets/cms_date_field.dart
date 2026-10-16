import 'package:flutter/material.dart';
import 'package:rijiki/core/theme/app_colors.dart';
import 'package:rijiki/core/utils/date_format.dart';

class CmsDateField extends StatelessWidget {
  const CmsDateField({
    super.key,
    required this.label,
    required this.value,
    required this.onPick,
    required this.onClear,
    this.errorText,
    this.enabled = true,
  });

  final String label;
  final DateTime? value;
  final VoidCallback onPick;
  final VoidCallback onClear;
  final String? errorText;
  final bool enabled;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final current = value;

    return InkWell(
      borderRadius: BorderRadius.circular(12),
      onTap: enabled ? onPick : null,
      child: InputDecorator(
        decoration: InputDecoration(
          labelText: label,
          errorText: errorText,
          suffixIcon: current == null
              ? const Icon(Icons.calendar_month_rounded)
              : IconButton(
                  tooltip: 'Kosongkan',
                  icon: const Icon(Icons.close_rounded),
                  onPressed: enabled ? onClear : null,
                ),
        ),
        child: Text(
          current == null ? 'Tidak diisi' : formatDate(current),
          style: textTheme.bodyLarge?.copyWith(
            color: current == null
                ? AppColors.onSurfaceVariant
                : AppColors.onSurface,
          ),
        ),
      ),
    );
  }
}
