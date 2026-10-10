import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:rijiki/core/theme/app_colors.dart';
import 'package:rijiki/core/theme/app_spacing.dart';
import 'package:rijiki/features/dashboard/presentation/controllers/dashboard_controller.dart';
import 'package:rijiki/features/dashboard/presentation/widgets/dashboard_message_card.dart';
import 'package:rijiki/features/dashboard/presentation/widgets/repeat_customer_tile.dart';
import 'package:rijiki/features/dashboard/presentation/widgets/skeleton_block.dart';

class RepeatCustomerPage extends ConsumerWidget {
  const RepeatCustomerPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(allRepeatCustomersProvider);
    final textTheme = Theme.of(context).textTheme;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(title: const Text('Repeat customer')),
      body: RefreshIndicator(
        color: AppColors.primaryDark,
        onRefresh: () async {
          ref.invalidate(allRepeatCustomersProvider);
          await ref.read(allRepeatCustomersProvider.future);
        },
        child: ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(AppSpacing.lg),
          children: [
            async.when(
              data: (customers) {
                if (customers.isEmpty) {
                  return const DashboardMessageCard(
                    icon: Icons.favorite_border_rounded,
                    message:
                        'Belum ada pelanggan dengan lebih dari satu order selesai.',
                  );
                }
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '${customers.length} pelanggan dengan lebih dari satu order selesai.',
                      style: textTheme.bodyMedium?.copyWith(
                        color: AppColors.onSurfaceVariant,
                      ),
                    ),
                    const SizedBox(height: AppSpacing.md),
                    Container(
                      decoration: BoxDecoration(
                        color: AppColors.surface,
                        borderRadius: BorderRadius.circular(
                          AppSpacing.radiusLg,
                        ),
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
                  ],
                );
              },
              loading: () => const SkeletonBlock(height: 420),
              error: (error, stackTrace) => DashboardMessageCard(
                icon: Icons.cloud_off_rounded,
                message: 'Gagal memuat daftar repeat customer.',
                actionLabel: 'Coba lagi',
                onAction: () => ref.invalidate(allRepeatCustomersProvider),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
