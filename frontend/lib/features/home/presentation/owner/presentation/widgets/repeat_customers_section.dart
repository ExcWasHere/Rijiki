import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:rijiki/app/router/route_paths.dart';
import 'package:rijiki/core/theme/app_colors.dart';
import 'package:rijiki/core/theme/app_spacing.dart';
import 'package:rijiki/features/home/presentation/owner/presentation/controllers/dashboard_controller.dart';
import 'package:rijiki/features/home/presentation/owner/presentation/widgets/dashboard_message_card.dart';
import 'package:rijiki/features/home/presentation/owner/presentation/widgets/dashboard_section_header.dart';
import 'package:rijiki/features/home/presentation/owner/presentation/widgets/repeat_customer_tile.dart';
import 'package:rijiki/features/home/presentation/owner/presentation/widgets/skeleton_block.dart';

class RepeatCustomersSection extends ConsumerWidget {
  const RepeatCustomersSection({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(dashboardRepeatCustomersProvider);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        DashboardSectionHeader(
          title: 'Repeat customer',
          actionLabel: 'Lihat semua',
          onAction: () => context.push(RoutePaths.ownerRepeatCustomers),
        ),
        const SizedBox(height: AppSpacing.sm + 4),
        async.when(
          data: (customers) => customers.isEmpty
              ? const DashboardMessageCard(
                  icon: Icons.favorite_border_rounded,
                  message:
                      'Belum ada pelanggan dengan lebih dari satu order selesai.',
                )
              : Container(
                  decoration: BoxDecoration(
                    color: AppColors.surface,
                    borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
                    border: Border.all(
                      color: AppColors.outline.withValues(alpha: 0.3),
                    ),
                  ),
                  child: Column(
                    children: [
                      for (var i = 0; i < customers.length; i++) ...[
                        if (i > 0)
                          Divider(
                            height: 1,
                            indent: AppSpacing.md,
                            endIndent: AppSpacing.md,
                            color: AppColors.outline.withValues(alpha: 0.2),
                          ),
                        RepeatCustomerTile(
                          customer: customers[i],
                          rank: i + 1,
                        ),
                      ],
                    ],
                  ),
                ),
          loading: () => const SkeletonBlock(height: 210),
          error: (error, stackTrace) => DashboardMessageCard(
            icon: Icons.cloud_off_rounded,
            message: 'Gagal memuat repeat customer.',
            actionLabel: 'Coba lagi',
            onAction: () => ref.invalidate(dashboardRepeatCustomersProvider),
          ),
        ),
      ],
    );
  }
}
