import 'package:flutter/material.dart';
import 'package:rijiki/core/theme/app_colors.dart';
import 'package:rijiki/core/theme/app_spacing.dart';

class WorkerDashboardPage extends StatelessWidget {
  const WorkerDashboardPage({super.key});

  @override
  Widget build(BuildContext context) {

    const totalOrders = 12;
    const waitingOrders = 3;
    const cleaningOrders = 4;
    const completedOrders = 5;

    final orders = [
      const _WorkerOrder(
        number: 'RJ-001',
        shoeName: 'White Sneakers',
        service: 'Deep Cleaning',
        status: 'Menunggu',
        imageUrl:
            'https://images.unsplash.com/photo-1549298916-b41d501d3772?w=300',
      ),
      const _WorkerOrder(
        number: 'RJ-002',
        shoeName: 'Black Sneakers',
        service: 'Deep Cleaning',
        status: 'Diproses',
        imageUrl:
            'https://images.unsplash.com/photo-1552346154-21d32810aba3?w=300',
      ),
    ];

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(AppSpacing.md),
          children: [
            Row(
              children: [
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: AppColors.primary.withOpacity(0.10),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Icon(
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
                        'Halo, Worker!',
                        style: Theme.of(context)
                            .textTheme
                            .titleMedium
                            ?.copyWith(
                              fontWeight: FontWeight.w700,
                              color: AppColors.onSurface,
                            ),
                      ),
                      const SizedBox(height: 3),
                      Text(
                        'Siap memproses pesanan hari ini?',
                        style: Theme.of(context)
                            .textTheme
                            .bodySmall
                            ?.copyWith(
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
                  icon: const Icon(
                    Icons.notifications_none_rounded,
                  ),
                ),
              ],
            ),

            const SizedBox(height: AppSpacing.lg),

            // RINGKASAN ORDER
            Text(
              'Ringkasan Hari Ini',
              style: Theme.of(context)
                  .textTheme
                  .titleMedium
                  ?.copyWith(
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
                _WorkerStatCard(
                  title: 'Pesanan Hari Ini',
                  value: totalOrders,
                  icon: Icons.receipt_long_outlined,
                  color: AppColors.primary,
                ),
                _WorkerStatCard(
                  title: 'Menunggu',
                  value: waitingOrders,
                  icon: Icons.schedule_rounded,
                  color: const Color(0xFFD97706),
                ),
                _WorkerStatCard(
                  title: 'Diproses',
                  value: cleaningOrders,
                  icon: Icons.cleaning_services_outlined,
                  color: AppColors.primary,
                ),
                _WorkerStatCard(
                  title: 'Selesai',
                  value: completedOrders,
                  icon: Icons.check_circle_outline_rounded,
                  color: const Color(0xFF16845B),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.lg),

            // ORDER YANG PERLU DITANGANI
            Row(
              children: [
                Expanded(
                  child: Text(
                    'Pesanan yang Perlu Ditangani',
                    style: Theme.of(context)
                        .textTheme
                        .titleMedium
                        ?.copyWith(
                          fontWeight: FontWeight.w700,
                          color: AppColors.onSurface,
                        ),
                  ),
                ),
                TextButton(
                  onPressed: () {
                    // TODO: Arahkan ke tab Pesan.
                  },
                  child: const Text('Lihat semua'),
                ),
              ],
            ),

            const SizedBox(height: AppSpacing.xs),

            ...orders.map(
              (order) => Padding(
                padding: const EdgeInsets.only(
                  bottom: AppSpacing.sm,
                ),
                child: _WorkerOrderCard(order: order),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _WorkerStatCard extends StatelessWidget {
  const _WorkerStatCard({
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
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: AppColors.onSurfaceVariant.withOpacity(0.25),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Icon(icon, color: color, size: 23),
          Text(
            '$value',
            style: Theme.of(context)
                .textTheme
                .headlineSmall
                ?.copyWith(
                  fontWeight: FontWeight.w700,
                  color: AppColors.onSurface,
                ),
          ),
          Text(
            title,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: Theme.of(context)
                .textTheme
                .bodySmall
                ?.copyWith(
                  color: AppColors.onSurfaceVariant,
                ),
          ),
        ],
      ),
    );
  }
}


class _WorkerOrderCard extends StatelessWidget {
  const _WorkerOrderCard({
    required this.order,
  });

  final _WorkerOrder order;

  @override
  Widget build(BuildContext context) {
    final statusColor = switch (order.status) {
      'Menunggu' => const Color(0xFFD97706),
      'Diproses' => AppColors.primary,
      'Delivery' => const Color(0xFF7C3AED),
      'Selesai' => const Color(0xFF16845B),
      _ => AppColors.onSurfaceVariant,
    };

    return Material(
      color: AppColors.surface,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: () {
          // TODO: Buka detail order.
        },
        child: Container(
          padding: const EdgeInsets.all(AppSpacing.md),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: AppColors.onSurfaceVariant.withValues(alpha: 0.25),
            ),
          ),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '#${order.number}',
                      style: Theme.of(context)
                          .textTheme
                          .labelMedium
                          ?.copyWith(
                            fontWeight: FontWeight.w700,
                            color: AppColors.onSurface,
                          ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      order.shoeName,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context)
                          .textTheme
                          .titleSmall
                          ?.copyWith(
                            fontWeight: FontWeight.w600,
                            color: AppColors.onSurface,
                          ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      order.service,
                      style: Theme.of(context)
                          .textTheme
                          .bodySmall
                          ?.copyWith(
                            color: AppColors.onSurfaceVariant,
                          ),
                    ),
                    const SizedBox(height: 10),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 9,
                        vertical: 5,
                      ),
                      decoration: BoxDecoration(
                        color: statusColor.withValues(alpha: 0.10),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        order.status,
                        style: Theme.of(context)
                            .textTheme
                            .labelSmall
                            ?.copyWith(
                              color: statusColor,
                              fontWeight: FontWeight.w600,
                            ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              const Icon(
                Icons.chevron_right_rounded,
                color: AppColors.onSurfaceVariant,
              ),
            ],
          ),
        ),
      ),
    );
  }
}


class _WorkerOrder {
  const _WorkerOrder({
    required this.number,
    required this.shoeName,
    required this.service,
    required this.status,
    required this.imageUrl,
  });

  final String number;
  final String shoeName;
  final String service;
  final String status;
  final String imageUrl;
}