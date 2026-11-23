import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:rijiki/app/providers.dart';
import 'package:rijiki/core/theme/app_colors.dart';
import 'package:rijiki/core/theme/app_spacing.dart';
import 'package:rijiki/features/finance/data/finance_repository_impl.dart';
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

class TransactionListPage extends ConsumerStatefulWidget {
  const TransactionListPage({super.key});

  @override
  ConsumerState<TransactionListPage> createState() =>
      _TransactionListPageState();
}

/// Satu baris di daftar: judul tanggal atau kartu berisi transaksi hari itu.
sealed class _Row {
  const _Row();
}

class _DateRow extends _Row {
  const _DateRow(this.day);

  final DateTime day;
}

class _GroupRow extends _Row {
  const _GroupRow(this.transactions);

  final List<FinancialTransaction> transactions;
}

class _TransactionListPageState extends ConsumerState<TransactionListPage> {
  static const int _pageSize = FinanceRepositoryImpl.defaultPageSize;

  /// Ambang jarak ke bawah yang memicu halaman berikutnya dimuat.
  static const double _loadMoreThreshold = 600;

  final ScrollController _scroll = ScrollController();
  final List<FinancialTransaction> _items = [];

  TransactionFilter _filter = const TransactionFilter();

  /// Filter yang datanya sedang tampil, dipakai untuk membedakan refresh
  /// (data lama tetap tampil) dari ganti filter (daftar dikosongkan).
  TransactionFilter? _loadedFilter;
  int _total = 0;
  int _page = 0;
  bool _loading = true;
  bool _loadingMore = false;
  bool _loadFailed = false;
  bool _loadMoreFailed = false;
  bool _hasMore = false;

  // Agregat dan grouping dihitung sekali per perubahan data, bukan tiap build.
  double _income = 0;
  double _expense = 0;
  List<_Row> _rows = const [];

  @override
  void initState() {
    super.initState();
    _filter = ref.read(transactionFilterProvider);
    ref.listenManual<TransactionFilter>(transactionFilterProvider, (prev, next) {
      if (_sameFilter(prev, next)) return;
      _filter = next;
      unawaited(_loadFirstPage());
    });
    _scroll.addListener(_maybeLoadMore);
    // Muat setelah frame pertama supaya setState pertama tidak jatuh di
    // tengah proses build.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      unawaited(_loadFirstPage());
    });
  }

  @override
  void dispose() {
    _scroll.dispose();
    super.dispose();
  }

  static bool _sameFilter(TransactionFilter? a, TransactionFilter? b) {
    if (a == null || b == null) return a == b;
    return a.type == b.type &&
        a.expenseType == b.expenseType &&
        a.start == b.start &&
        a.end == b.end;
  }

  Future<void> _loadFirstPage() async {
    final filter = _filter;
    final filterChanged = !_sameFilter(_loadedFilter, filter);
    setState(() {
      if (filterChanged) {
        _items.clear();
        _total = 0;
        _rebuildRows();
      }
      _loading = true;
      _loadFailed = false;
      _loadMoreFailed = false;
      _hasMore = false;
    });
    try {
      final result = await fetchFinanceTransactionPage(
        ref.read(financeRepositoryProvider),
        filter,
        page: 1,
        limit: _pageSize,
      );
      if (!mounted || !_sameFilter(filter, _filter)) return;
      setState(() {
        _loadedFilter = filter;
        _items
          ..clear()
          ..addAll(result.items);
        _total = result.total;
        _page = result.page;
        _hasMore = result.hasMore;
        _loading = false;
        _rebuildRows();
      });
      _autoLoadIfNotScrollable();
    } catch (_) {
      if (!mounted || !_sameFilter(filter, _filter)) return;
      setState(() {
        _loading = false;
        _loadFailed = true;
        _rebuildRows();
      });
    }
  }

  Future<void> _loadMore() async {
    if (_loading || _loadingMore || !_hasMore) return;
    final filter = _filter;
    final nextPage = _page + 1;
    setState(() {
      _loadingMore = true;
      _loadMoreFailed = false;
    });
    try {
      final result = await fetchFinanceTransactionPage(
        ref.read(financeRepositoryProvider),
        filter,
        page: nextPage,
        limit: _pageSize,
      );
      if (!mounted || !_sameFilter(filter, _filter)) return;
      setState(() {
        _items.addAll(result.items);
        _total = result.total;
        _page = result.page;
        // Halaman kosong berarti sudah habis, walau total server lebih besar.
        _hasMore = result.items.isNotEmpty && result.hasMore;
        _loadingMore = false;
        _rebuildRows();
      });
      _autoLoadIfNotScrollable();
    } catch (_) {
      if (!mounted || !_sameFilter(filter, _filter)) return;
      setState(() {
        _loadingMore = false;
        _loadMoreFailed = true;
      });
    }
  }

  /// Isi yang lebih pendek dari layar tidak memicu scroll, jadi halaman
  /// berikutnya dimuat langsung setelah frame.
  void _autoLoadIfNotScrollable() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted || !_hasMore || _loadingMore || _loadMoreFailed) return;
      if (!_scroll.hasClients) return;
      if (_scroll.position.extentAfter < _loadMoreThreshold) {
        unawaited(_loadMore());
      }
    });
  }

  void _maybeLoadMore() {
    if (!_scroll.hasClients || !_hasMore || _loadingMore || _loadMoreFailed) {
      return;
    }
    if (_scroll.position.extentAfter < _loadMoreThreshold) {
      unawaited(_loadMore());
    }
  }

  void _rebuildRows() {
    var income = 0.0;
    var expense = 0.0;
    final groups = <DateTime, List<FinancialTransaction>>{};
    for (final transaction in _items) {
      if (transaction.isIncome) {
        income += transaction.amount;
      } else {
        expense += transaction.amount;
      }
      final date = transaction.transactionDate;
      groups
          .putIfAbsent(DateTime(date.year, date.month, date.day), () => [])
          .add(transaction);
    }

    _income = income;
    _expense = expense;
    _rows = [
      for (final entry in groups.entries) ...[
        _DateRow(entry.key),
        _GroupRow(entry.value),
      ],
    ];
  }

  Future<void> _pickRange() async {
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

  @override
  Widget build(BuildContext context) {
    final filter = ref.watch(transactionFilterProvider);
    final notifier = ref.read(transactionFilterProvider.notifier);
    final showFooter = _hasMore || _loadingMore || _loadMoreFailed;

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
              initialExpenseType: filter.type == TransactionTypeFilter.expense
                  ? filter.expenseType
                  : null,
            ),
          ),
        ],
      ),
      body: RefreshIndicator(
        color: AppColors.primaryDark,
        onRefresh: _loadFirstPage,
        child: ListView.builder(
          controller: _scroll,
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.fromLTRB(
            AppSpacing.lg,
            AppSpacing.md,
            AppSpacing.lg,
            AppSpacing.xl,
          ),
          itemCount: 1 + _rows.length + (showFooter ? 1 : 0),
          itemBuilder: (context, index) {
            if (index == 0) {
              return _buildHeader(context, filter, notifier);
            }
            if (index > _rows.length) {
              return _buildFooter();
            }
            return _buildRow(_rows[index - 1]);
          },
        ),
      ),
    );
  }

  Widget _buildHeader(
    BuildContext context,
    TransactionFilter filter,
    TransactionFilterNotifier notifier,
  ) {
    final textTheme = Theme.of(context).textTheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        TransactionFilterBar(
          filter: filter,
          onTypeChanged: notifier.selectType,
          onExpenseTypeChanged: notifier.selectExpenseType,
          onPickRange: _pickRange,
          onClearRange: notifier.clearRange,
        ),
        const SizedBox(height: AppSpacing.md),
        if (_loading && _items.isEmpty)
          const _ListSkeleton()
        else if (_loadFailed && _items.isEmpty)
          FinanceStateCard(
            child: ErrorState(
              message: 'Gagal memuat transaksi.',
              onRetry: _loadFirstPage,
            ),
          )
        else if (_items.isEmpty)
          FinanceStateCard(
            child: EmptyState(
              icon: Icons.receipt_long_outlined,
              title: filter.isDefault
                  ? 'Belum ada transaksi'
                  : 'Tidak ada transaksi untuk filter ini',
              actionLabel: filter.isDefault ? null : 'Reset filter',
              onAction: notifier.reset,
            ),
          )
        else ...[
          TransactionSummaryStrip(income: _income, expense: _expense),
          const SizedBox(height: AppSpacing.md),
          Text(
            '$_total transaksi',
            style: textTheme.bodyMedium?.copyWith(
              color: AppColors.onSurfaceVariant,
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildRow(_Row row) {
    return switch (row) {
      _DateRow(:final day) => Padding(
        padding: const EdgeInsets.only(
          left: AppSpacing.xs,
          top: AppSpacing.md,
          bottom: AppSpacing.sm,
        ),
        child: Text(
          formatDateGroup(day),
          style: Theme.of(context).textTheme.labelLarge?.copyWith(
            color: AppColors.onSurfaceVariant,
          ),
        ),
      ),
      _GroupRow(:final transactions) => _GroupCard(transactions: transactions),
    };
  }

  Widget _buildFooter() {
    if (_loadMoreFailed) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: AppSpacing.md),
        child: Center(
          child: TextButton(
            onPressed: _loadMore,
            child: const Text('Muat lagi'),
          ),
        ),
      );
    }
    return const Padding(
      padding: EdgeInsets.symmetric(vertical: AppSpacing.md),
      child: Center(
        child: SizedBox(
          width: 22,
          height: 22,
          child: CircularProgressIndicator(strokeWidth: 2),
        ),
      ),
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
