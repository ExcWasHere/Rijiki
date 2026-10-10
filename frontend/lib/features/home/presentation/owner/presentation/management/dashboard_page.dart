import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:rijiki/app/router/route_paths.dart';
import 'package:rijiki/core/session/session_provider.dart';
import 'package:rijiki/core/theme/app_colors.dart';
import 'package:rijiki/core/theme/app_spacing.dart';
import 'package:rijiki/features/dashboard/presentation/controllers/dashboard_controller.dart';
import 'package:rijiki/features/dashboard/presentation/widgets/owner_greeting_header.dart';
import 'package:rijiki/features/dashboard/presentation/widgets/period_selector.dart';
import 'package:rijiki/features/dashboard/presentation/widgets/recent_orders_list.dart';
import 'package:rijiki/features/dashboard/presentation/widgets/repeat_customers_section.dart';
import 'package:rijiki/features/dashboard/presentation/widgets/revenue_hero_card.dart';
import 'package:rijiki/features/dashboard/presentation/widgets/skeleton_block.dart';
import 'package:rijiki/features/dashboard/presentation/widgets/summary_stat_row.dart';
import 'package:rijiki/features/dashboard/presentation/widgets/testimonial_export_shortcut.dart';

class DashboardPage extends ConsumerWidget {
  const DashboardPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(sessionProvider);
    final name = _firstName(user?.fullName, user?.email);
    final period = ref.watch(dashboardPeriodProvider);
    final async = ref.watch(dashboardSummaryProvider);
    final summary = async.value;

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        bottom: false,
        child: RefreshIndicator(
          color: AppColors.primaryDark,
          onRefresh: () => refreshDashboard(ref),
          child: ListView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.fromLTRB(
              AppSpacing.lg,
              AppSpacing.md,
              AppSpacing.lg,
              AppSpacing.xl,
            ),
            children: [
              OwnerGreetingHeader(
                name: name,
                avatarUrl: user?.avatarUrl,
                onAvatarTap: () => context.go(RoutePaths.ownerProfile),
              ),
              const SizedBox(height: AppSpacing.lg),
              PeriodSelector(
                selected: period,
                onChanged: (value) =>
                    ref.read(dashboardPeriodProvider.notifier).select(value),
              ),
              const SizedBox(height: AppSpacing.md),
              if (summary != null)
                AnimatedOpacity(
                  duration: const Duration(milliseconds: 200),
                  opacity: async.isLoading ? 0.55 : 1,
                  child: Column(
                    children: [
                      RevenueHeroCard(summary: summary),
                      const SizedBox(height: AppSpacing.md),
                      SummaryStatRow(
                        summary: summary,
                        onActiveOrdersTap: () =>
                            context.go(RoutePaths.ownerOrders),
                      ),
                    ],
                  ),
                )
              else if (async.hasError)
                _ErrorCard(onRetry: () => refreshDashboard(ref))
              else
                const _SummarySkeleton(),
              const SizedBox(height: AppSpacing.xl),
              RecentOrdersSection(
                onSeeAll: () => context.go(RoutePaths.ownerOrders),
              ),
              const SizedBox(height: AppSpacing.xl),
              const RepeatCustomersSection(),
              const SizedBox(height: AppSpacing.xl),
              TestimonialExportShortcut(
                onTap: () => ScaffoldMessenger.of(context)
                  ..hideCurrentSnackBar()
                  ..showSnackBar(
                    const SnackBar(
                      content: Text('Fitur unduh rekap testimoni segera hadir.'),
                    ),
                  ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  static String _firstName(String? fullName, String? email) {
    final trimmed = fullName?.trim() ?? '';
    if (trimmed.isNotEmpty) return trimmed.split(RegExp(r'\s+')).first;
    final local = email?.split('@').first ?? '';
    return local.isEmpty ? 'Owner' : local;
  }
}

class _SummarySkeleton extends StatelessWidget {
  const _SummarySkeleton();

  @override
  Widget build(BuildContext context) {
    return const Column(
      children: [
        SkeletonBlock(height: 260),
        SizedBox(height: AppSpacing.md),
        Row(
          children: [
            Expanded(child: SkeletonBlock(height: 110)),
            SizedBox(width: AppSpacing.sm + 4),
            Expanded(child: SkeletonBlock(height: 110)),
          ],
        ),
        SizedBox(height: AppSpacing.sm + 4),
        SkeletonBlock(height: 76),
      ],
    );
  }
}

class _ErrorCard extends StatelessWidget {
  const _ErrorCard({required this.onRetry});

  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return Container(
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
        border: Border.all(color: AppColors.outline.withValues(alpha: 0.3)),
      ),
      child: Column(
        children: [
          const Icon(
            Icons.cloud_off_rounded,
            size: AppSpacing.iconLg,
            color: AppColors.onSurfaceVariant,
          ),
          const SizedBox(height: AppSpacing.sm),
          Text('Gagal memuat dashboard', style: textTheme.titleMedium),
          const SizedBox(height: AppSpacing.md),
          OutlinedButton(onPressed: onRetry, child: const Text('Coba lagi')),
        ],
      ),
    );
  }
}
