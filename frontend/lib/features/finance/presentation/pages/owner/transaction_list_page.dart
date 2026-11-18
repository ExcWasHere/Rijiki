import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:rijiki/core/theme/app_colors.dart';
import 'package:rijiki/core/theme/app_spacing.dart';
import 'package:rijiki/features/finance/domain/financial_transaction.dart';
import 'package:rijiki/features/finance/domain/transaction_filter.dart';
import 'package:rijiki/features/finance/presentation/controllers/finance_controller.dart';
import 'package:rijiki/features/finance/presentation/utils/finance_format.dart';
import 'package:rijiki/features/finance/presentation/widgets/export_range_sheet.dart';
import 'package:rijiki/features/finance/presentation/widgets/finance_state_card.dart';
import 'package:rijiki/features/finance/presentation/widgets/transaction_detail_sheet.dart';
import 'package:rijiki/features/finance/presentation/widgets/transaction_filter_bar.dart';
import 'package:rijiki/features/finance/presentation/widgets/transaction_summary_strip.dart';
import 'package:rijiki/features/finance/presentation/widgets/transaction_tile.dart';
import 'package:rijiki/shared/widgets/empty_state.dart';
import 'package:rijiki/shared/widgets/error_state.dart';
import 'package:rijiki/shared/widgets/loading_skeleton.dart';

class TransactionListPage extends ConsumerWidget {
  const TransactionListPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final filter = ref.watch(transactionFilterProvider);
    final notifier = ref.read(transactionFilterProvider.notifier);
    final async = ref.watch(financeTransactionsProvider);
    final list = async.value;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Rekap transaksi'),
        actions: [
          IconButton(
            tooltip: 'Ekspor Excel',
            icon: const Icon(Icons.file_download_outlined),
            onPressed: () => showExportRangeSheet(
              context,
              initialRange: filter.hasRange
                  ? DateTimeRange(start: filter.start!, end: filter.end!)
                  : null,
              initialExpenseType:
                  filter.type == TransactionTypeFilter.expense
                  ? filter.expenseType
                  : null,
            ),
          ),
        ],
      ),
      body: RefreshIndicator(
        color: AppColors.primaryDark,
        onRefresh: () => refreshTransactions(ref),
        child: ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.fromLTRB(
            AppSpacing.lg,
            AppSpacing.md,
            AppSpacing.lg,
            AppSpacing.xl,
          ),
          children: [
            TransactionFilterBar(
              filter: filter,
              onTypeChanged: notifier.selectType,
              onExpenseTypeChanged: notifier.selectExpenseType,
              onPickRange: () => _pickRange(context, ref),
              onClearRange: notifier.clearRange,
            ),
            const SizedBox(height: AppSpacing.md),
            if (list != null)
              AnimatedOpacity(
                duration: const Duration(milliseconds: 200),
                opacity: async.isLoading ? 0.55 : 1,
                child: _Content(
                  transactions: list,
                  isDefaultFilter: filter.isDefault,
                  onReset: notifier.reset,
                ),
              )
            else if (async.hasError)
              FinanceStateCard(
                child: ErrorState(
                  message: 'Gagal memuat transaksi.',
                  onRetry: () => ref.invalidate(financeTransactionsProvider),
                ),
              )
            else
              const _ListSkeleton(),
          ],
        ),
      ),
    );
  }

  Future<void> _pickRange(BuildContext context, WidgetRef ref) async {
    final filter = ref.read(transactionFilterProvider);
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);

    final picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime(today.year - 2),
      lastDate: today,
      initialDateRange: filter.hasRange
          ? DateTimeRange(start: filter.start!, end: filter.end!)
          : null,
      helpText: 'Pilih rentang tanggal',
      saveText: 'Terapkan',
    );
    if (picked == null) return;
    ref
        .read(transactionFilterProvider.notifier)
        .setRange(picked.start, picked.end);
  }
}

class _Content extends StatelessWidget {
  const _Content({
    required this.transactions,
    required this.isDefaultFilter,
    required this.onReset,
  });

  final List<FinancialTransaction> transactions;
  final bool isDefaultFilter;
  final VoidCallback onReset;

  @override
  Widget build(BuildContext context) {
    if (transactions.isEmpty) {
      return FinanceStateCard(
        child: EmptyState(
          icon: Icons.receipt_long_outlined,
          title: isDefaultFilter
              ? 'Belum ada transaksi'
              : 'Tidak ada transaksi untuk filter ini',
          actionLabel: isDefaultFilter ? null : 'Reset filter',
          onAction: onReset,
        ),
      );
    }

    var income = 0.0;
    var expense = 0.0;
    final groups = <DateTime, List<FinancialTransaction>>{};
    for (final t in transactions) {
      if (t.isIncome) {
        income += t.amount;
      } else {
        expense += t.amount;
      }
      final d = t.transactionDate;
      groups.putIfAbsent(DateTime(d.year, d.month, d.day), () => []).add(t);
    }

    final textTheme = Theme.of(context).textTheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        TransactionSummaryStrip(income: income, expense: expense),
        const SizedBox(height: AppSpacing.md),
        Text(
          '${transactions.length} transaksi',
          style: textTheme.bodyMedium?.copyWith(
            color: AppColors.onSurfaceVariant,
          ),
        ),
        for (final entry in groups.entries) ...[
          const SizedBox(height: AppSpacing.md),
          Padding(
            padding: const EdgeInsets.only(
              left: AppSpacing.xs,
              bottom: AppSpacing.sm,
            ),
            child: Text(
              formatDateGroup(entry.key),
              style: textTheme.labelLarge?.copyWith(
                color: AppColors.onSurfaceVariant,
              ),
            ),
          ),
          _GroupCard(transactions: entry.value),
        ],
      ],
    );
  }
}

class _GroupCard extends StatelessWidget {
  const _GroupCard({required this.transactions});

  final List<FinancialTransaction> transactions;

  @override
  Widget build(BuildContext context) {
    return Container(
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
        border: Border.all(color: AppColors.outline.withValues(alpha: 0.3)),
      ),
      child: Material(
        color: AppColors.surface,
        child: Column(
          children: [
            for (var i = 0; i < transactions.length; i++) ...[
              if (i > 0)
                Divider(
                  height: 1,
                  indent: AppSpacing.md,
                  endIndent: AppSpacing.md,
                  color: AppColors.outline.withValues(alpha: 0.2),
                ),
              TransactionTile(
                transaction: transactions[i],
                onTap: () =>
                    showTransactionDetailSheet(context, transactions[i]),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _ListSkeleton extends StatelessWidget {
  const _ListSkeleton();

  @override
  Widget build(BuildContext context) {
    const radius = AppSpacing.radiusLg;
    return const Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        LoadingSkeleton(height: 76, radius: radius),
        SizedBox(height: AppSpacing.md),
        LoadingSkeleton(height: 200, radius: radius),
        SizedBox(height: AppSpacing.md),
        LoadingSkeleton(height: 260, radius: radius),
      ],
    );
  }
}
