import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:rijiki/core/theme/app_colors.dart';
import 'package:rijiki/core/theme/app_spacing.dart';
import 'package:rijiki/features/points/domain/point_ledger_entry.dart';
import 'package:rijiki/features/points/presentation/controllers/point_history_controller.dart';
import 'package:rijiki/features/points/presentation/utils/point_history_format.dart';
import 'package:rijiki/shared/widgets/empty_state.dart';
import 'package:rijiki/shared/widgets/error_state.dart';
import 'package:rijiki/shared/widgets/loading_skeleton.dart';

class PointHistoryPage extends ConsumerStatefulWidget {
  const PointHistoryPage({super.key});

  @override
  ConsumerState<PointHistoryPage> createState() => _PointHistoryPageState();
}

class _PointHistoryPageState extends ConsumerState<PointHistoryPage> {
  final ScrollController _scroll = ScrollController();

  @override
  void initState() {
    super.initState();
    _scroll.addListener(_onScroll);
  }

  @override
  void dispose() {
    _scroll
      ..removeListener(_onScroll)
      ..dispose();
    super.dispose();
  }

  void _onScroll() {
    if (!_scroll.hasClients) return;
    final position = _scroll.position;
    if (position.pixels >= position.maxScrollExtent - 240) {
      ref.read(pointLedgerProvider.notifier).loadMore();
    }
  }

  Future<void> _refresh() async {
    ref.invalidate(pointBalanceProvider);
    ref.invalidate(pointLedgerProvider);
    try {
      await ref.read(pointLedgerProvider.future);
    } catch (_) {}
  }

  @override
  Widget build(BuildContext context) {
    final balance = ref.watch(pointBalanceProvider);
    final ledger = ref.watch(pointLedgerProvider);
    final state = ledger.value;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(title: const Text('Riwayat poin')),
      body: RefreshIndicator(
        color: AppColors.primaryDark,
        onRefresh: _refresh,
        child: ListView(
          controller: _scroll,
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.fromLTRB(
            AppSpacing.md,
            AppSpacing.md,
            AppSpacing.md,
            AppSpacing.xl,
          ),
          children: [
            _BalanceCard(balance: balance),
            const SizedBox(height: AppSpacing.lg),
            if (state != null)
              _LedgerList(
                state: state,
                onRetryMore: () =>
                    ref.read(pointLedgerProvider.notifier).loadMore(),
              )
            else if (ledger.hasError)
              ErrorState(
                message: 'Gagal memuat riwayat poin.',
                onRetry: () => ref.invalidate(pointLedgerProvider),
              )
            else
              const Column(
                children: [
                  LoadingSkeleton(height: 68, radius: AppSpacing.radiusMd),
                  SizedBox(height: AppSpacing.sm),
                  LoadingSkeleton(height: 68, radius: AppSpacing.radiusMd),
                  SizedBox(height: AppSpacing.sm),
                  LoadingSkeleton(height: 68, radius: AppSpacing.radiusMd),
                ],
              ),
          ],
        ),
      ),
    );
  }
}

class _BalanceCard extends StatelessWidget {
  const _BalanceCard({required this.balance});

  final AsyncValue<PointBalance> balance;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final value = balance.value;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
        border: Border.all(color: AppColors.outline.withValues(alpha: 0.3)),
      ),
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: const Color(0xFFFFC83D).withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(14),
            ),
            child: const Icon(
              Icons.star_rounded,
              size: 28,
              color: Color(0xFFFFB800),
            ),
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Saldo poin',
                  style: textTheme.labelMedium?.copyWith(
                    color: AppColors.onSurfaceVariant,
                  ),
                ),
                const SizedBox(height: 2),
                if (value != null)
                  Text(
                    formatPoints(value.balance),
                    style: textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.w800,
                      color: AppColors.primaryDark,
                    ),
                  )
                else if (balance.hasError)
                  Text(
                    'Saldo belum bisa dimuat',
                    style: textTheme.bodyMedium?.copyWith(
                      color: AppColors.onSurfaceVariant,
                    ),
                  )
                else
                  const LoadingSkeleton(width: 90, height: 28, radius: 8),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _LedgerList extends StatelessWidget {
  const _LedgerList({required this.state, required this.onRetryMore});

  final PointLedgerState state;
  final VoidCallback onRetryMore;

  @override
  Widget build(BuildContext context) {
    if (state.items.isEmpty) {
      return const Padding(
        padding: EdgeInsets.only(top: AppSpacing.lg),
        child: EmptyState(
          icon: Icons.history_rounded,
          title: 'Belum ada riwayat poin',
          message:
              'Poin dari order yang selesai dan penukaran hadiah akan tercatat di sini.',
        ),
      );
    }

    return Column(
      children: [
        Container(
          clipBehavior: Clip.antiAlias,
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
            border: Border.all(color: AppColors.outline.withValues(alpha: 0.3)),
          ),
          child: Column(
            children: [
              for (var i = 0; i < state.items.length; i++) ...[
                if (i > 0)
                  Divider(
                    height: 1,
                    indent: AppSpacing.md,
                    endIndent: AppSpacing.md,
                    color: AppColors.outline.withValues(alpha: 0.2),
                  ),
                _LedgerTile(entry: state.items[i]),
              ],
            ],
          ),
        ),
        const SizedBox(height: AppSpacing.md),
        if (state.loadingMore)
          const Padding(
            padding: EdgeInsets.all(AppSpacing.sm),
            child: SizedBox(
              width: 22,
              height: 22,
              child: CircularProgressIndicator(strokeWidth: 2),
            ),
          )
        else if (state.loadMoreFailed)
          TextButton.icon(
            onPressed: onRetryMore,
            icon: const Icon(Icons.refresh_rounded),
            label: const Text('Gagal memuat, coba lagi'),
          )
        else if (!state.hasMore)
          Text(
            'Semua riwayat sudah tampil',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: AppColors.onSurfaceVariant,
            ),
          ),
      ],
    );
  }
}

class _LedgerTile extends StatelessWidget {
  const _LedgerTile({required this.entry});

  final PointLedgerEntry entry;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final color = entry.color;
    final muted = textTheme.bodySmall?.copyWith(
      color: AppColors.onSurfaceVariant,
    );

    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.md,
        vertical: AppSpacing.sm + 4,
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(entry.type.icon, size: 22, color: color),
          ),
          const SizedBox(width: AppSpacing.sm + 4),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  entry.title,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 2),
                Text(entry.subtitle, style: muted),
                Text(entry.dateLabel, style: muted),
              ],
            ),
          ),
          const SizedBox(width: AppSpacing.sm),
          Text(
            formatSignedPoints(entry.pointsAmount),
            style: textTheme.titleMedium?.copyWith(
              color: color,
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }
}
