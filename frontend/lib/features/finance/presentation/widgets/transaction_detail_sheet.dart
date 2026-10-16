import 'package:flutter/material.dart';
import 'package:rijiki/core/theme/app_colors.dart';
import 'package:rijiki/core/theme/app_spacing.dart';
import 'package:rijiki/core/utils/rupiah_formatter.dart';
import 'package:rijiki/features/finance/domain/financial_transaction.dart';
import 'package:rijiki/features/finance/presentation/expense_type_ui.dart';
import 'package:rijiki/features/finance/presentation/utils/finance_format.dart';

Future<void> showTransactionDetailSheet(
  BuildContext context,
  FinancialTransaction transaction,
) {
  return showModalBottomSheet<void>(
    context: context,
    showDragHandle: true,
    isScrollControlled: true,
    backgroundColor: AppColors.surface,
    builder: (_) => _TransactionDetailSheet(transaction: transaction),
  );
}

class _TransactionDetailSheet extends StatelessWidget {
  const _TransactionDetailSheet({required this.transaction});

  final FinancialTransaction transaction;

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

    final rows = <(String, String)>[
      ('Jenis', t.isIncome ? 'Pemasukan' : 'Pengeluaran'),
      if (type != null) ('Tipe', type.label),
      ('Tanggal', formatDate(t.transactionDate)),
      if (t.vendorName != null) ('Toko / penyedia', t.vendorName!),
      if (t.quantity != null) ('Jumlah', formatQuantity(t.quantity!, t.unit)),
      if (t.description != null) ('Keterangan', t.description!),
      ('Dicatat lewat', t.inputSource == InputSource.ai ? 'Input AI' : 'Manual'),
      if (t.receiptImageUrl != null) ('Nota', 'Terlampir'),
    ];

    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(
          AppSpacing.lg,
          0,
          AppSpacing.lg,
          AppSpacing.lg,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: 0.14),
                    borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
                  ),
                  child: Icon(icon, color: color),
                ),
                const SizedBox(width: AppSpacing.md),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(title, style: textTheme.titleMedium),
                      const SizedBox(height: 2),
                      Text(
                        '${t.isIncome ? '+' : '-'}${RupiahFormatter.full(t.amount)}',
                        style: textTheme.titleLarge?.copyWith(
                          color: t.isIncome
                              ? AppColors.success
                              : AppColors.onSurface,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.md),
            const Divider(),
            for (final (label, value) in rows)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 10),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    SizedBox(
                      width: 120,
                      child: Text(
                        label,
                        style: textTheme.bodyMedium?.copyWith(
                          color: AppColors.onSurfaceVariant,
                        ),
                      ),
                    ),
                    Expanded(
                      child: Text(
                        value,
                        textAlign: TextAlign.end,
                        style: textTheme.bodyMedium,
                      ),
                    ),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }
}
