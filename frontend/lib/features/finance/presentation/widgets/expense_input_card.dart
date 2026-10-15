import 'package:flutter/material.dart';
import 'package:rijiki/core/theme/app_colors.dart';
import 'package:rijiki/core/theme/app_spacing.dart';
import 'package:rijiki/features/finance/presentation/utils/finance_format.dart';
import 'package:rijiki/shared/widgets/image_picker_field.dart';

class ExpenseInputCard extends StatelessWidget {
  const ExpenseInputCard({
    super.key,
    required this.controller,
    required this.date,
    required this.receiptPath,
    required this.onPickDate,
    required this.onReceiptChanged,
    this.enabled = true,
  });

  final TextEditingController controller;
  final DateTime date;
  final String? receiptPath;
  final VoidCallback onPickDate;
  final ValueChanged<String?> onReceiptChanged;
  final bool enabled;

  static const String _hint =
      'Contoh: Beli sabun 2 botol 45rb sama sikat 3 biji 30rb di Toko Maju.';

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
        border: Border.all(color: AppColors.outline.withValues(alpha: 0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: AppColors.rijikiOrange.withValues(alpha: 0.14),
                  borderRadius: BorderRadius.circular(AppSpacing.radiusMd - 2),
                ),
                child: const Icon(
                  Icons.auto_awesome_rounded,
                  size: AppSpacing.iconSm + 2,
                  color: AppColors.rijikiOrange,
                ),
              ),
              const SizedBox(width: AppSpacing.sm + 4),
              Expanded(
                child: Text(
                  'Ceritain pengeluarannya, biar AI yang catat',
                  style: textTheme.titleMedium,
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          TextField(
            controller: controller,
            enabled: enabled,
            minLines: 4,
            maxLines: 7,
            maxLength: 1000,
            textCapitalization: TextCapitalization.sentences,
            keyboardType: TextInputType.multiline,
            decoration: InputDecoration(
              hintText: _hint,
              hintStyle: textTheme.bodyMedium?.copyWith(
                color: AppColors.onSurfaceVariant.withValues(alpha: 0.7),
              ),
              counterText: '',
            ),
          ),
          const SizedBox(height: AppSpacing.sm + 4),
          Wrap(
            spacing: AppSpacing.sm,
            runSpacing: AppSpacing.sm,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              _DatePill(
                label: formatDateGroup(date),
                onTap: enabled ? onPickDate : null,
              ),
              ImagePickerField(
                path: receiptPath,
                onChanged: onReceiptChanged,
                label: 'Lampirkan nota',
                attachedLabel: 'Nota terlampir',
                enabled: enabled,
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _DatePill extends StatelessWidget {
  const _DatePill({required this.label, required this.onTap});

  final String label;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return Material(
      color: AppColors.primary.withValues(alpha: 0.18),
      shape: const StadiumBorder(
        side: BorderSide(color: AppColors.primaryDark),
      ),
      child: InkWell(
        customBorder: const StadiumBorder(),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(12, 8, 14, 8),
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
            ],
          ),
        ),
      ),
    );
  }
}
