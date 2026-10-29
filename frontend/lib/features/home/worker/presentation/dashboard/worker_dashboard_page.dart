import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:rijiki/app/router/route_paths.dart';
import 'package:rijiki/core/enums/order_status.dart';
import 'package:rijiki/core/error/failure.dart';
import 'package:rijiki/core/session/session_provider.dart';
import 'package:rijiki/core/theme/app_colors.dart';
import 'package:rijiki/core/theme/app_spacing.dart';
import 'package:rijiki/features/home/worker/presentation/dashboard/worker_delivery_run_page.dart';
import 'package:rijiki/features/order/domain/customer_order.dart';
import 'package:rijiki/features/order/domain/staff_order_repository.dart';
import 'package:rijiki/features/order/presentation/controllers/courier_tracking_sender.dart';
import 'package:rijiki/features/order/presentation/controllers/staff_order_controller.dart';
import 'package:rijiki/features/order/presentation/widgets/staff_order_card.dart';
import 'package:rijiki/shared/widgets/empty_state.dart';
import 'package:rijiki/shared/widgets/error_state.dart';
import 'package:rijiki/shared/widgets/loading_skeleton.dart';

class WorkerDashboardPage extends ConsumerWidget {
  const WorkerDashboardPage({super.key});

  static const int _previewCount = 3;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(sessionProvider);
    final mine = ref.watch(staffOrdersProvider(StaffOrderList.primary));
    final queue = ref.watch(staffOrdersProvider(StaffOrderList.unassigned));
    final sender = ref.watch(courierTrackingSenderProvider);
    final textTheme = Theme.of(context).textTheme;

    final myOrders = mine.value ?? const <CustomerOrder>[];
    final activeOrders = myOrders.where((o) => o.status.isActive).toList()
      ..sort((a, b) => a.createdAt.compareTo(b.createdAt));
    final cleaning = myOrders
        .where((o) => o.status == OrderStatus.cleaning)
        .length;
    final completed = myOrders
        .where((o) => o.status == OrderStatus.completed)
        .length;
    final queueCount = queue.value?.length ?? 0;
    final deliveries = deliveryRunOf(myOrders);

    final firstName = (user?.fullName ?? '').trim().split(' ').first;

    Future<void> refresh() async {
      ref.invalidate(staffOrdersProvider);
      ref.read(courierTrackingSenderProvider.notifier).sync();
      try {
        await Future.wait([
          ref.read(staffOrdersProvider(StaffOrderList.primary).future),
          ref.read(staffOrdersProvider(StaffOrderList.unassigned).future),
        ]);
      } catch (_) {
      }
    }

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: refresh,
          child: ListView(
            padding: const EdgeInsets.all(AppSpacing.md),
            children: [
              Row(
                children: [
                  Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      color: AppColors.primary.withValues(alpha: 0.10),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: const Icon(
                      Icons.person_outline_rounded,
                      color: AppColors.primary,
                      size: 28,
                    ),
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          firstName.isEmpty ? 'Halo!' : 'Halo, $firstName!',
                          style: textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w700,
                            color: AppColors.onSurface,
                          ),
                        ),
                        const SizedBox(height: 3),
                        Text(
                          'Siap memproses pesanan hari ini?',
                          style: textTheme.bodySmall?.copyWith(
                            color: AppColors.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    onPressed: () {
                      // TODO: Buka halaman notifikasi.
                    },
                    icon: const Icon(Icons.notifications_none_rounded),
                  ),
                ],
              ),
              if (deliveries.isNotEmpty) ...[
                const SizedBox(height: AppSpacing.md),
                _DeliveryBanner(count: deliveries.length, sender: sender),
              ],
              const SizedBox(height: AppSpacing.lg),
              Text(
                'Ringkasan',
                style: textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w700,
                  color: AppColors.onSurface,
                ),
              ),
              const SizedBox(height: AppSpacing.sm),
              GridView.count(
                crossAxisCount: 2,
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                crossAxisSpacing: AppSpacing.sm,
                mainAxisSpacing: AppSpacing.sm,
                childAspectRatio: 1.25,
                children: [
                  _StatCard(
                    title: 'Tugas aktif',
                    value: activeOrders.length,
                    icon: Icons.receipt_long_outlined,
                    color: AppColors.primary,
                  ),
                  _StatCard(
                    title: 'Antrean',
                    value: queueCount,
                    icon: Icons.schedule_rounded,
                    color: AppColors.warning,
                  ),
                  _StatCard(
                    title: 'Dikerjakan',
                    value: cleaning,
                    icon: Icons.cleaning_services_outlined,
                    color: AppColors.primaryDark,
                  ),
                  _StatCard(
                    title: 'Selesai',
                    value: completed,
                    icon: Icons.check_circle_outline_rounded,
                    color: AppColors.success,
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.lg),
              Row(
                children: [
                  Expanded(
                    child: Text(
                      'Pesanan yang perlu ditangani',
                      style: textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w700,
                        color: AppColors.onSurface,
                      ),
                    ),
                  ),
                  TextButton(
                    onPressed: () => context.go(RoutePaths.workerOrders),
                    child: const Text('Lihat semua'),
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.xs),
              ..._buildPreview(context, ref, mine, activeOrders),
            ],
          ),
        ),
      ),
    );
  }

  List<Widget> _buildPreview(
    BuildContext context,
    WidgetRef ref,
    AsyncValue<List<CustomerOrder>> mine,
    List<CustomerOrder> activeOrders,
  ) {
    if (mine.isLoading && !mine.hasValue) {
      return const [LoadingSkeleton(height: 150)];
    }
    if (mine.hasError && !mine.hasValue) {
      final error = mine.error;
      return [
        ErrorState(
          message: error is Failure
              ? error.message
              : 'Pesanan gagal dimuat. Coba lagi ya.',
          onRetry: () =>
              ref.invalidate(staffOrdersProvider(StaffOrderList.primary)),
        ),
      ];
    }
    if (activeOrders.isEmpty) {
      return const [
        EmptyState(
          icon: Icons.task_alt_rounded,
          title: 'Tidak ada tugas aktif',
          message: 'Ambil order dari tab Pesanan > Antrean.',
        ),
      ];
    }

    return [
      for (final order in activeOrders.take(_previewCount))
        Padding(
          padding: const EdgeInsets.only(bottom: AppSpacing.sm),
          child: StaffOrderCard(
            order: order,
            onTap: () =>
                context.push(RoutePaths.workerOrderDetailFor(order.id)),
          ),
        ),
    ];
  }
}

class _StatCard extends StatelessWidget {
  const _StatCard({
    required this.title,
    required this.value,
    required this.icon,
    required this.color,
  });

  final String title;
  final int value;
  final IconData icon;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: AppColors.onSurfaceVariant.withValues(alpha: 0.25),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Icon(icon, color: color, size: 23),
          Text(
            '$value',
            style: textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.w700,
              color: AppColors.onSurface,
            ),
          ),
          Text(
            title,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: textTheme.bodySmall?.copyWith(
              color: AppColors.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }
}

class _DeliveryBanner extends ConsumerWidget {
  const _DeliveryBanner({required this.count, required this.sender});

  final int count;
  final CourierSenderState sender;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final textTheme = Theme.of(context).textTheme;
    final hasIssue = sender.issue != null;
    final color = hasIssue ? AppColors.warning : AppColors.rijikiOrange;

    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.two_wheeler_rounded, color: color),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  'Sedang mengantar $count order',
                  style: textTheme.titleSmall,
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            hasIssue
                ? 'Pelacakan lokasi belum aktif, customer belum bisa melihat posisimu.'
                : 'Lokasimu dibagikan ke customer selama pengantaran.',
            style: textTheme.bodySmall,
          ),
          const SizedBox(height: 10),
          Wrap(
            spacing: 8,
            children: [
              FilledButton(
                onPressed: () => context.push(RoutePaths.workerDeliveryRun),
                child: const Text('Buka peta pengantaran'),
              ),
              if (hasIssue)
                OutlinedButton(
                  onPressed: () =>
                      ref.read(courierTrackingSenderProvider.notifier).retry(),
                  child: const Text('Aktifkan lokasi'),
                ),
            ],
          ),
        ],
      ),
    );
  }
}
