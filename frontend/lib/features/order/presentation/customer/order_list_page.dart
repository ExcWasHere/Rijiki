import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:rijiki/app/router/route_paths.dart';
import 'package:rijiki/core/theme/app_colors.dart';
import 'package:rijiki/core/theme/app_spacing.dart';
import 'package:rijiki/features/order/domain/order_filter.dart';
import 'package:rijiki/features/order/presentation/controllers/order_list_controller.dart';
import 'package:rijiki/features/order/presentation/widgets/order_card.dart';
import 'package:rijiki/features/order/presentation/widgets/order_filter_chips.dart';
import 'package:rijiki/shared/widgets/empty_state.dart';
import 'package:rijiki/shared/widgets/error_state.dart';
import 'package:rijiki/shared/widgets/loading_skeleton.dart';
import 'package:rijiki/shared/widgets/state_card.dart';

class OrderListPage extends ConsumerWidget {
  const OrderListPage({super.key});

  static const EdgeInsets _listPadding = EdgeInsets.fromLTRB(
    AppSpacing.lg,
    0,
    AppSpacing.lg,
    AppSpacing.xl,
  );

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final orders = ref.watch(filteredOrdersProvider);
    final filter = ref.watch(orderFilterProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        bottom: false,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(
                AppSpacing.lg,
                AppSpacing.md,
                AppSpacing.lg,
                0,
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      'Order',
                      style: Theme.of(context).textTheme.headlineSmall,
                    ),
                  ),
                  FilledButton.icon(
                    onPressed: () => context.push(RoutePaths.orderCreateFor()),
                    icon: const Icon(Icons.add_rounded, size: 20),
                    label: const Text('Buat order'),
                    style: FilledButton.styleFrom(
                      minimumSize: const Size(0, 40),
                      padding: const EdgeInsets.symmetric(horizontal: 14),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: AppSpacing.md),
            OrderFilterChips(
              selected: filter,
              onSelected: ref.read(orderFilterProvider.notifier).select,
            ),
            const SizedBox(height: AppSpacing.md),
            Expanded(
              child: RefreshIndicator(
                color: AppColors.primaryDark,
                onRefresh: () => refreshOrders(ref),
                child: orders.when(
                  loading: () => ListView(
                    physics: const AlwaysScrollableScrollPhysics(),
                    padding: _listPadding,
                    children: [
                      for (var i = 0; i < 3; i++) ...[
                        if (i > 0) const SizedBox(height: 12),
                        const LoadingSkeleton(height: 168),
                      ],
                    ],
                  ),
                  error: (_, _) => ListView(
                    physics: const AlwaysScrollableScrollPhysics(),
                    padding: _listPadding,
                    children: [
                      StateCard(
                        child: ErrorState(
                          onRetry: () => ref.invalidate(ordersProvider),
                        ),
                      ),
                    ],
                  ),
                  data: (list) {
                    if (list.isEmpty) {
                      return ListView(
                        physics: const AlwaysScrollableScrollPhysics(),
                        padding: _listPadding,
                        children: [
                          StateCard(child: _emptyState(context, ref, filter)),
                        ],
                      );
                    }
                    return ListView.separated(
                      physics: const AlwaysScrollableScrollPhysics(),
                      padding: _listPadding,
                      itemCount: list.length,
                      separatorBuilder: (_, _) => const SizedBox(height: 12),
                      itemBuilder: (context, index) {
                        final order = list[index];
                        return OrderCard(
                          order: order,
                          onTap: () => context.push(
                            RoutePaths.orderDetailFor(order.id),
                          ),
                        );
                      },
                    );
                  },
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _emptyState(BuildContext context, WidgetRef ref, OrderFilter filter) {
    if (filter == OrderFilter.all) {
      return EmptyState(
        icon: Icons.receipt_long_outlined,
        title: 'Belum ada order',
        message: 'Mulai dengan membuat order pertamamu.',
        actionLabel: 'Buat order',
        onAction: () => context.push(RoutePaths.orderCreateFor()),
      );
    }
    final message = switch (filter) {
      OrderFilter.inProgress => 'Tidak ada order yang sedang berjalan.',
      OrderFilter.completed => 'Belum ada order yang selesai.',
      OrderFilter.cancelled => 'Tidak ada order yang dibatalkan.',
      OrderFilter.all => '',
    };
    return EmptyState(
      icon: Icons.inbox_outlined,
      title: 'Tidak ada order di sini',
      message: message,
      actionLabel: 'Lihat semua order',
      onAction: () => ref
          .read(orderFilterProvider.notifier)
          .select(OrderFilter.all),
    );
  }
}
