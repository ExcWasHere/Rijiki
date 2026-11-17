import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:rijiki/app/router/route_paths.dart';
import 'package:rijiki/core/theme/app_colors.dart';
import 'package:rijiki/core/theme/app_spacing.dart';
import 'package:rijiki/core/utils/date_formatter.dart';
import 'package:rijiki/features/profile/domain/profile_history.dart';
import 'package:rijiki/features/profile/presentation/controllers/profile_history_controllers.dart';
import 'package:rijiki/shared/widgets/empty_state.dart';
import 'package:rijiki/shared/widgets/error_state.dart';
import 'package:rijiki/shared/widgets/loading_skeleton.dart';

/// "Sepatu saya": catatan sepatu yang pernah dicuci, diambil dari riwayat order.
/// Tidak ada unggahan foto sepatu di sini.
class MyShoesPage extends ConsumerStatefulWidget {
  const MyShoesPage({super.key});

  @override
  ConsumerState<MyShoesPage> createState() => _MyShoesPageState();
}

class _MyShoesPageState extends ConsumerState<MyShoesPage> {
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
      ref.read(myShoesProvider.notifier).loadMore();
    }
  }

  Future<void> _refresh() async {
    ref.invalidate(myShoesProvider);
    try {
      await ref.read(myShoesProvider.future);
    } catch (_) {}
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(myShoesProvider);
    final data = state.value;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(title: const Text('Sepatu saya')),
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
            if (data != null)
              _ShoeList(
                state: data,
                onRetryMore: () => ref.read(myShoesProvider.notifier).loadMore(),
              )
            else if (state.hasError)
              ErrorState(
                message: 'Gagal memuat sepatu.',
                onRetry: () => ref.invalidate(myShoesProvider),
              )
            else
              const Column(
                children: [
                  LoadingSkeleton(height: 84, radius: AppSpacing.radiusMd),
                  SizedBox(height: AppSpacing.sm),
                  LoadingSkeleton(height: 84, radius: AppSpacing.radiusMd),
                  SizedBox(height: AppSpacing.sm),
                  LoadingSkeleton(height: 84, radius: AppSpacing.radiusMd),
                ],
              ),
          ],
        ),
      ),
    );
  }
}

class _ShoeList extends StatelessWidget {
  const _ShoeList({required this.state, required this.onRetryMore});

  final HistoryList<MyShoe> state;
  final VoidCallback onRetryMore;

  @override
  Widget build(BuildContext context) {
    if (state.items.isEmpty) {
      return const Padding(
        padding: EdgeInsets.only(top: AppSpacing.lg),
        child: EmptyState(
          icon: Icons.cleaning_services_outlined,
          title: 'Belum ada sepatu',
          message:
              'Sepatu yang pernah kamu cucikan di Rijiki akan tercatat di sini '
              'setelah order pertamamu.',
        ),
      );
    }

    return Column(
      children: [
        Text(
          '${state.total} sepatu pernah dicuci di Rijiki.',
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
            color: AppColors.onSurfaceVariant,
          ),
        ),
        const SizedBox(height: AppSpacing.sm),
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
                _ShoeTile(shoe: state.items[i]),
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
          ),
      ],
    );
  }
}

class _ShoeTile extends StatelessWidget {
  const _ShoeTile({required this.shoe});

  final MyShoe shoe;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final muted = textTheme.bodySmall?.copyWith(
      color: AppColors.onSurfaceVariant,
    );

    return InkWell(
      onTap: shoe.orderId.isEmpty
          ? null
          : () => context.push(RoutePaths.orderDetailFor(shoe.orderId)),
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.md,
          vertical: AppSpacing.sm + 4,
        ),
        child: Row(
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: AppColors.primary.withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(
                Icons.cleaning_services_outlined,
                color: AppColors.primaryDark,
              ),
            ),
            const SizedBox(width: AppSpacing.sm + 4),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    shoe.title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    [
                      if (shoe.serviceName != null) shoe.serviceName!,
                      '${shoe.quantity} pasang',
                    ].join(' · '),
                    style: muted,
                  ),
                  Text(
                    '${shoe.orderNumber} · '
                    '${DateFormatter.shortDate(shoe.orderDate)}',
                    style: muted,
                  ),
                ],
              ),
            ),
            const Icon(Icons.chevron_right_rounded),
          ],
        ),
      ),
    );
  }
}
