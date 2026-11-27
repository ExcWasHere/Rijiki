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
import 'package:rijiki/shared/widgets/private_image.dart';

/// "Rating & testimoni": riwayat penilaian yang pernah diberikan customer.
class MyRatingsPage extends ConsumerStatefulWidget {
  const MyRatingsPage({super.key});

  @override
  ConsumerState<MyRatingsPage> createState() => _MyRatingsPageState();
}

class _MyRatingsPageState extends ConsumerState<MyRatingsPage> {
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
      ref.read(myRatingsProvider.notifier).loadMore();
    }
  }

  Future<void> _refresh() async {
    ref.invalidate(myRatingsProvider);
    try {
      await ref.read(myRatingsProvider.future);
    } catch (_) {}
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(myRatingsProvider);
    final data = state.value;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(title: const Text('Rating & testimoni')),
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
            if (data != null) ...[
              _SummaryCard(
                total: data.total,
                average: data.average,
              ),
              const SizedBox(height: AppSpacing.lg),
              if (data.items.isEmpty)
                const EmptyState(
                  icon: Icons.star_border_rounded,
                  title: 'Belum ada rating',
                  message:
                      'Setelah order selesai, kamu bisa menilai hasil cucian '
                      'dan testimoni akan muncul di sini.',
                )
              else
                _RatingList(
                  state: data,
                  onRetryMore: () =>
                      ref.read(myRatingsProvider.notifier).loadMore(),
                ),
            ] else if (state.hasError)
              ErrorState(
                message: 'Gagal memuat rating.',
                onRetry: () => ref.invalidate(myRatingsProvider),
              )
            else
              const Column(
                children: [
                  LoadingSkeleton(height: 88, radius: AppSpacing.radiusMd),
                  SizedBox(height: AppSpacing.sm),
                  LoadingSkeleton(height: 120, radius: AppSpacing.radiusMd),
                ],
              ),
          ],
        ),
      ),
    );
  }
}

class _SummaryCard extends StatelessWidget {
  const _SummaryCard({required this.total, required this.average});

  final int total;
  final double? average;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

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
                  'Rating rata-rata',
                  style: textTheme.labelMedium?.copyWith(
                    color: AppColors.onSurfaceVariant,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  average == null
                      ? 'Belum ada penilaian'
                      : '${average!.toStringAsFixed(1)} dari 5',
                  style: textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.w800,
                    color: AppColors.primaryDark,
                  ),
                ),
                Text(
                  '$total rating diberikan',
                  style: textTheme.bodySmall?.copyWith(
                    color: AppColors.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _RatingList extends StatelessWidget {
  const _RatingList({required this.state, required this.onRetryMore});

  final HistoryList<CustomerRating> state;
  final VoidCallback onRetryMore;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        for (final rating in state.items) ...[
          _RatingCard(rating: rating),
          const SizedBox(height: AppSpacing.sm + 4),
        ],
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

class _RatingCard extends StatelessWidget {
  const _RatingCard({required this.rating});

  final CustomerRating rating;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final muted = textTheme.bodySmall?.copyWith(
      color: AppColors.onSurfaceVariant,
    );

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
              for (var i = 1; i <= 5; i++)
                Icon(
                  i <= rating.ratingValue
                      ? Icons.star_rounded
                      : Icons.star_border_rounded,
                  size: 20,
                  color: const Color(0xFFFFB800),
                ),
              const Spacer(),
              if (rating.isFeatured)
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 2,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.rijikiOrange.withValues(alpha: 0.18),
                    borderRadius: BorderRadius.circular(999),
                  ),
                  child: Text(
                    'Tampil di beranda',
                    style: textTheme.labelSmall?.copyWith(
                      fontWeight: FontWeight.w700,
                      color: AppColors.onSurface,
                    ),
                  ),
                ),
            ],
          ),
          if (rating.comment != null && rating.comment!.trim().isNotEmpty) ...[
            const SizedBox(height: AppSpacing.sm),
            Text(rating.comment!.trim(), style: textTheme.bodyMedium),
          ],
          if (rating.photoKey != null) ...[
            const SizedBox(height: AppSpacing.sm),
            ClipRRect(
              borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
              child: SizedBox(
                height: 140,
                width: double.infinity,
                child: PrivateImage(imageKey: rating.photoKey!),
              ),
            ),
          ],
          const SizedBox(height: AppSpacing.sm),
          Row(
            children: [
              Expanded(
                child: Text(
                  [
                    if (rating.orderNumber != null &&
                        rating.orderNumber!.isNotEmpty)
                      rating.orderNumber!,
                    DateFormatter.shortDate(rating.createdAt),
                  ].join(' · '),
                  style: muted,
                ),
              ),
              if (rating.orderId.isNotEmpty)
                TextButton(
                  onPressed: () =>
                      context.push(RoutePaths.orderDetailFor(rating.orderId)),
                  child: const Text('Lihat order'),
                ),
            ],
          ),
          if (rating.workerName != null)
            Text('Ditangani ${rating.workerName}', style: muted),
        ],
      ),
    );
  }
}
