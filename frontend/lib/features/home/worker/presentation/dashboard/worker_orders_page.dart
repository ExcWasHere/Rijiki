
import 'package:flutter/material.dart';
import 'package:rijiki/core/theme/app_colors.dart';
import 'package:rijiki/core/theme/app_spacing.dart';
import 'worker_order_detail_page.dart';

class WorkerOrdersPage extends StatefulWidget {
  const WorkerOrdersPage({super.key});

  @override
  State<WorkerOrdersPage> createState() => _WorkerOrdersPageState();
}

class _WorkerOrdersPageState extends State<WorkerOrdersPage> {
  String selectedFilter = 'Semua';

  static const Color primaryBlue = AppColors.primary;
  static const Color lightBlue = AppColors.background;
  static const Color textDark = AppColors.onSurface;
  static const Color textGrey = AppColors.onSurfaceVariant;
  static const Color borderColor = AppColors.onSurfaceVariant;

  final List<Map<String, dynamic>> orders = [
    {
      'id': 'RJK-001',
      'customer': 'Andi Pratama',
      'shoe': 'Sneakers Putih',
      'service': 'Deep Clean',
      'status': 'Menunggu',
      'date': '14 Okt 2026',
      'icon': Icons.cleaning_services_outlined,
    },
    {
      'id': 'RJK-002',
      'customer': 'Dina Putri',
      'shoe': 'Sneakers Hitam',
      'service': 'Unyellowing',
      'status': 'Diproses',
      'date': '14 Okt 2026',
      'icon': Icons.water_drop_outlined,
    },
    {
      'id': 'RJK-003',
      'customer': 'Raka Wijaya',
      'shoe': 'Running Shoes',
      'service': 'Regular Clean',
      'status': 'Diproses',
      'date': '13 Okt 2026',
      'icon': Icons.sports_outlined,
    },
    {
      'id': 'RJK-004',
      'customer': 'Nadia Safitri',
      'shoe': 'Canvas Shoes',
      'service': 'Deep Clean',
      'status': 'Selesai',
      'date': '12 Okt 2026',
      'icon': Icons.checkroom_outlined,
    },
  ];

  List<Map<String, dynamic>> get filteredOrders {
    if (selectedFilter == 'Semua') return orders;

    return orders
        .where((order) => order['status'] == selectedFilter)
        .toList();
  }

  int countStatus(String status) {
    if (status == 'Semua') return orders.length;

    return orders.where((order) => order['status'] == status).length;
  }

  Color statusColor(String status) {
    switch (status) {
      case 'Menunggu':
        return AppColors.rijikiOrange;
      case 'Diproses':
        return AppColors.primaryDark;
      case 'Selesai':
        return AppColors.success;
      default:
        return AppColors.onSurfaceVariant;
    }
  }

  void showOrderDetail(Map<String, dynamic> order) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(24),
        ),
      ),
      builder: (context) {
        final status = order['status'] as String;

        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Container(
                    width: 42,
                    height: 4,
                    decoration: BoxDecoration(
                      color: borderColor.withValues(alpha: 0.25),
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                ),
                const SizedBox(height: 24),
                const Text(
                  'Detail Pesanan',
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: textDark,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  order['id'] as String,
                  style: const TextStyle(color: textGrey),
                ),
                const SizedBox(height: 20),
                _detailRow('Nama Customer', order['customer'] as String),
                _detailRow('Jenis Sepatu', order['shoe'] as String),
                _detailRow('Layanan', order['service'] as String),
                _detailRow('Tanggal', order['date'] as String),
                const SizedBox(height: 12),
                Row(
                  children: [
                    const Text(
                      'Status',
                      style: TextStyle(color: textGrey),
                    ),
                    const Spacer(),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 7,
                      ),
                      decoration: BoxDecoration(
                        color: statusColor(status).withValues(alpha: 0.10),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        status,
                        style: TextStyle(
                          color: statusColor(status),
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 24),
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton(
                    onPressed: () => Navigator.pop(context),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: primaryBlue,
                      side: const BorderSide(color: primaryBlue),
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: const Text('Tutup'),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _detailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Text(
              label,
              style: const TextStyle(color: AppColors.onSurfaceVariant),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Text(
              value,
              textAlign: TextAlign.end,
              style: const TextStyle(
                color: AppColors.onSurface,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 24, 20, 12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Pesanan',
                    style: TextStyle(
                      fontSize: 27,
                      fontWeight: FontWeight.bold,
                      color: textDark,
                    ),
                  ),
                  const SizedBox(height: 14),
                  _buildFilters(),
                ],
              ),
            ),
            Expanded(
              child: filteredOrders.isEmpty
                  ? _buildEmptyState()
                  : ListView.builder(
                      padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
                      itemCount: filteredOrders.length,
                      itemBuilder: (context, index) {
                        final order = filteredOrders[index];

                        return Padding(
                          padding: const EdgeInsets.only(bottom: 14),
                          child: _buildOrderCard(order),
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }

  // Filter kapsul, mengikuti tampilan EventPage.
  Widget _buildFilters() {
    const filters = [
      'Semua',
      'Menunggu',
      'Diproses',
      'Selesai',
    ];

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: filters.map((filter) {
          final isSelected = selectedFilter == filter;
          final count = countStatus(filter);

          return Padding(
            padding: const EdgeInsets.only(right: AppSpacing.xs),
            child: GestureDetector(
              onTap: () {
                setState(() {
                  selectedFilter = filter;
                });
              },
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 180),
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 9,
                ),
                decoration: BoxDecoration(
                  color: isSelected
                      ? AppColors.primary
                      : AppColors.background,
                  borderRadius: BorderRadius.circular(30),
                  border: Border.all(
                    color: isSelected
                        ? AppColors.primary
                        : AppColors.onSurfaceVariant
                            .withValues(alpha: 0.25),
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      filter,
                      style: Theme.of(context)
                          .textTheme
                          .labelMedium
                          ?.copyWith(
                            color: isSelected
                                ? AppColors.surface
                                : AppColors.onSurface,
                            fontWeight: isSelected
                                ? FontWeight.w600
                                : FontWeight.w500,
                          ),
                    ),
                    const SizedBox(width: 6),
                    Text(
                      '$count',
                      style: Theme.of(context)
                          .textTheme
                          .labelSmall
                          ?.copyWith(
                            color: isSelected
                                ? Colors.white.withValues(alpha: 0.85)
                                : AppColors.onSurfaceVariant,
                            fontWeight: FontWeight.w600,
                          ),
                    ),
                  ],
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildOrderCard(Map<String, dynamic> order) {
    final status = order['status'] as String;
    final color = statusColor(status);

    return Container(
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: AppColors.onSurfaceVariant.withValues(alpha: 0.25),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  order['id'] as String,
                  style: const TextStyle(
                    color: textDark,
                    fontWeight: FontWeight.bold,
                    fontSize: 13,
                  ),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 8,
                  vertical: 5,
                ),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.10),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  status,
                  style: TextStyle(
                    color: color,
                    fontSize: 10,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            order['shoe'] as String,
            style: const TextStyle(
              color: textDark,
              fontWeight: FontWeight.w600,
              fontSize: 15,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            order['service'] as String,
            style: const TextStyle(
              color: primaryBlue,
              fontSize: 12,
            ),
          ),
          const SizedBox(height: 5),
          Text(
            order['customer'] as String,
            style: const TextStyle(
              color: textGrey,
              fontSize: 12,
            ),
          ),
          const SizedBox(height: 14),
          Divider(
            height: 1,
            color: borderColor.withValues(alpha: 0.25),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              const Icon(
                Icons.calendar_today_outlined,
                color: textGrey,
                size: 15,
              ),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  order['date'] as String,
                  style: const TextStyle(
                    color: textGrey,
                    fontSize: 12,
                  ),
                ),
              ),
              TextButton(
              onPressed: () async {
                final updatedOrder = await Navigator.push<Map<String, dynamic>>(
                  context,
                  MaterialPageRoute(
                    builder: (_) => WorkerOrderDetailPage(
                      order: Map<String, dynamic>.from(order),
                    ),
                  ),
                );

                if (updatedOrder != null && mounted) {
                  setState(() {
                    order.addAll(updatedOrder);
                  });
                }
              },
              child: const Text('Lihat Detail'),
            ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(22),
              decoration: const BoxDecoration(
                color: lightBlue,
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.inbox_outlined,
                size: 42,
                color: primaryBlue,
              ),
            ),
            const SizedBox(height: 18),
            const Text(
              'Belum Ada Pesanan',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: textDark,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Pesanan dengan status ini akan muncul di sini.',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: textGrey,
                height: 1.5,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
