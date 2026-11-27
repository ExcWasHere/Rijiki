import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:rijiki/app/router/route_paths.dart';
import 'package:rijiki/core/enums/user_role.dart';
import 'package:rijiki/core/error/failure.dart';
import 'package:rijiki/core/permissions/access_policy.dart';
import 'package:rijiki/core/session/session_provider.dart';
import 'package:rijiki/core/theme/app_colors.dart';
import 'package:rijiki/core/theme/app_spacing.dart';
import 'package:rijiki/features/order/domain/order_filter.dart';
import 'package:rijiki/features/order/domain/staff_order_repository.dart';
import 'package:rijiki/features/order/presentation/controllers/staff_order_controller.dart';
import 'package:rijiki/features/order/presentation/widgets/staff_order_card.dart';
import 'package:rijiki/shared/widgets/empty_state.dart';
import 'package:rijiki/shared/widgets/error_state.dart';
import 'package:rijiki/shared/widgets/loading_skeleton.dart';

class WorkerOrdersPage extends ConsumerStatefulWidget {
  const WorkerOrdersPage({super.key});

  @override
  ConsumerState<WorkerOrdersPage> createState() => _WorkerOrdersPageState();
}

class _WorkerOrdersPageState extends ConsumerState<WorkerOrdersPage> {
  StaffOrderList _list = StaffOrderList.primary;
  OrderFilter _filter = OrderFilter.all;

  static const Map<OrderFilter, String> _filterLabels = {
    OrderFilter.all: 'Semua',
    OrderFilter.inProgress: 'Aktif',
    OrderFilter.completed: 'Selesai',
    OrderFilter.cancelled: 'Dibatalkan',
  };

  Future<void> _refresh() async {
    ref.invalidate(staffOrdersProvider(_list));
    try {
      await ref.read(staffOrdersProvider(_list).future);
    } catch (_) {
    }
  }

  void _openDetail(String orderId) {
    final user = ref.read(sessionProvider);
    final path = user?.role == UserRole.owner
        ? RoutePaths.ownerOrderDetailFor(orderId)
        : RoutePaths.workerOrderDetailFor(orderId);
    context.push(path);
  }

  @override
  Widget build(BuildContext context) {
    final user = ref.watch(sessionProvider);
    final manageAll = AccessPolicy.canManageAllOrders(user);
    final orders = ref.watch(staffOrdersProvider(_list));
    final textTheme = Theme.of(context).textTheme;

    final primaryLabel = manageAll ? 'Semua order' : 'Tugas saya';
    final unassignedLabel = manageAll ? 'Belum di-assign' : 'Antrean';

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(
                AppSpacing.lg,
                AppSpacing.lg,
                AppSpacing.lg,
                AppSpacing.sm,
              ),
              child: Text(
                'Pesanan',
                style: textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
            _ChipRow(
              children: [
                _Chip(
                  label: primaryLabel,
                  selected: _list == StaffOrderList.primary,
                  onTap: () => setState(() => _list = StaffOrderList.primary),
                ),
                _Chip(
                  label: unassignedLabel,
                  selected: _list == StaffOrderList.unassigned,
                  onTap: () => setState(() => _list = StaffOrderList.unassigned),
                ),
              ],
            ),
            if (_list == StaffOrderList.primary) ...[
              const SizedBox(height: AppSpacing.sm),
              _ChipRow(
                children: [
                  for (final filter in OrderFilter.values)
                    _Chip(
                      label: _filterLabels[filter]!,
                      selected: _filter == filter,
                      subtle: true,
                      onTap: () => setState(() => _filter = filter),
                    ),
                ],
              ),
            ],
            const SizedBox(height: AppSpacing.sm),
            Expanded(
              child: orders.when(
                loading: () => ListView(
                  padding: const EdgeInsets.all(AppSpacing.lg),
                  children: const [
                    LoadingSkeleton(height: 150),
                    SizedBox(height: AppSpacing.md),
                    LoadingSkeleton(height: 150),
                  ],
                ),
                error: (error, _) => Center(
                  child: ErrorState(
                    message: error is Failure
                        ? error.message
                        : 'Pesanan gagal dimuat. Coba lagi ya.',
                    onRetry: () => ref.invalidate(staffOrdersProvider(_list)),
                  ),
                ),
                data: (items) {
                  final visible = _list == StaffOrderList.primary
                      ? items.where((o) => _filter.matches(o.status)).toList()
                      : items;

                  if (visible.isEmpty) {
                    return RefreshIndicator(
                      onRefresh: _refresh,
                      child: ListView(
                        padding: const EdgeInsets.all(AppSpacing.lg),
                        children: [
                          const SizedBox(height: (AppSpacing.lg * 2)),
                          EmptyState(
                            icon: Icons.inbox_outlined,
                            title: _list == StaffOrderList.unassigned
                                ? 'Tidak ada order menunggu'
                                : 'Belum ada pesanan',
                            message: _list == StaffOrderList.unassigned
                                ? 'Order baru dari customer akan muncul di sini.'
                                : 'Pesanan dengan filter ini akan muncul di sini.',
                          ),
                        ],
                      ),
                    );
                  }

                  return RefreshIndicator(
                    onRefresh: _refresh,
                    child: ListView.separated(
                      padding: const EdgeInsets.fromLTRB(
                        AppSpacing.lg,
                        0,
                        AppSpacing.lg,
                        (AppSpacing.lg * 2),
                      ),
                      itemCount: visible.length,
                      separatorBuilder: (_, _) =>
                          const SizedBox(height: AppSpacing.md),
                      itemBuilder: (context, index) {
                        final order = visible[index];
                        return StaffOrderCard(
                          order: order,
                          onTap: () => _openDetail(order.id),
                        );
                      },
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ChipRow extends StatelessWidget {
  const _ChipRow({required this.children});

  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 38,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
        itemCount: children.length,
        separatorBuilder: (_, _) => const SizedBox(width: 8),
        itemBuilder: (_, index) => children[index],
      ),
    );
  }
}

class _Chip extends StatelessWidget {
  const _Chip({
    required this.label,
    required this.selected,
    required this.onTap,
    this.subtle = false,
  });

  final String label;
  final bool selected;
  final bool subtle;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final fill = selected
        ? (subtle ? AppColors.primary.withValues(alpha: 0.18) : AppColors.primary)
        : AppColors.surface;
    final textColor = selected
        ? (subtle ? AppColors.primaryDark : AppColors.onPrimary)
        : AppColors.onSurfaceVariant;

    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 16),
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: fill,
          borderRadius: BorderRadius.circular(999),
          border: Border.all(
            color: selected
                ? (subtle ? AppColors.primaryDark : AppColors.primary)
                : AppColors.outline.withValues(alpha: 0.4),
          ),
        ),
        child: Text(
          label,
          style: Theme.of(context).textTheme.labelLarge?.copyWith(
            color: textColor,
          ),
        ),
      ),
    );
  }
}
