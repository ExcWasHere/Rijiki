import 'package:flutter/material.dart';
import 'package:rijiki/core/theme/app_colors.dart';
import 'package:rijiki/core/theme/app_spacing.dart';
import 'package:rijiki/core/utils/rupiah_formatter.dart';
import 'package:rijiki/features/finance/domain/financial_transaction.dart';
import 'package:rijiki/features/finance/presentation/expense_type_ui.dart';

class TransactionTile extends StatelessWidget {
  const TransactionTile({
    super.key,
    required this.transaction,
    required this.onTap,
  });

  final FinancialTransaction transaction;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final t = transaction;
    final type = t.expenseType;

    final color = t.isIncome
        ? AppColors.success
        : (type?.color ?? AppColors.onSurfaceVariant);
    final icon = t.isIncome
        ? Icons.payments_rounded
        : (type?.icon ?? Icons.more_horiz_rounded);

    final title = t.isIncome
        ? (t.itemName ?? 'Pemasukan')
        : (t.itemName ?? t.description ?? type?.label ?? 'Pengeluaran');

    final subtitleParts = <String>[
      if (t.isIncome)
        (t.description ?? 'Pemasukan order')
      else ...[
        if (type != null) type.label,
        if (t.vendorName != null) t.vendorName!,
      ],
    ];

    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.md,
          vertical: AppSpacing.sm + 4,
        ),
        child: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.14),
                borderRadius: BorderRadius.circular(AppSpacing.radiusMd - 2),
              ),
              child: Icon(icon, size: AppSpacing.iconSm + 2, color: color),
            ),
            const SizedBox(width: AppSpacing.sm + 4),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Flexible(
                        child: Text(
                          title,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: textTheme.titleSmall,
                        ),
                      ),
                      if (t.inputSource == InputSource.ai) ...[
                        const SizedBox(width: 4),
                        const Icon(
                          Icons.auto_awesome_rounded,
                          size: 14,
                          color: AppColors.primaryDark,
                        ),
                      ],
                    ],
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitleParts.join(' · '),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: textTheme.bodySmall?.copyWith(
                      color: AppColors.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: AppSpacing.sm),
            Text(
              '${t.isIncome ? '+' : '-'}${RupiahFormatter.full(t.amount)}',
              style: textTheme.titleSmall?.copyWith(
                color: t.isIncome ? AppColors.success : AppColors.onSurface,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
