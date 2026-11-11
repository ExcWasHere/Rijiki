import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:rijiki/app/router/route_paths.dart';
import 'package:rijiki/core/enums/user_role.dart';
import 'package:rijiki/core/session/session_provider.dart';
import 'package:rijiki/core/theme/app_colors.dart';
import 'package:rijiki/core/theme/app_spacing.dart';
import 'package:rijiki/core/utils/currency_formatter.dart';
import 'package:rijiki/features/order/presentation/controllers/staff_order_controller.dart';
import 'package:rijiki/features/payment/presentation/controllers/payment_controller.dart';
import 'package:rijiki/features/payment/presentation/widgets/payment_countdown.dart';
import 'package:rijiki/features/payment/presentation/widgets/qris_qr_card.dart';
import 'package:rijiki/shared/widgets/error_state.dart';
import 'package:rijiki/shared/widgets/loading_skeleton.dart';

/// Layar QRIS untuk order offline: QR ditampilkan di perangkat worker/owner
/// supaya customer di outlet bisa memindainya. Memakai [PaymentController]
/// yang sama dengan pembayaran online.
class WorkerQrisPaymentPage extends ConsumerWidget {
  const WorkerQrisPaymentPage({super.key, required this.orderId});

  final String orderId;

  static const List<String> _steps = [
    'Minta customer membuka e-wallet atau mobile banking.',
    'Customer memilih scan QR, lalu mengarahkan ke kode di atas.',
    'Pastikan nominal sesuai, lalu customer mengonfirmasi pembayaran.',
  ];

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final provider = paymentControllerProvider(orderId);
    final state = ref.watch(provider);
    final controller = ref.read(provider.notifier);
    final payment = state.payment;
    final isOwner = ref.watch(sessionProvider)?.role == UserRole.owner;
    // Tombol "Lihat pesanan" hanya bila order ini memang bisa dibuka pemanggil
    // (mis. bukan order yang ditugaskan ke worker lain).
    final canOpenOrder = ref.watch(staffOrderDetailProvider(orderId)).value != null;

    void leave() {
      if (context.canPop()) {
        context.pop();
      } else {
        context.go(isOwner ? RoutePaths.ownerOrders : RoutePaths.workerOrders);
      }
    }

    void openOrder() {
      context.pushReplacement(
        isOwner
            ? RoutePaths.ownerOrderDetailFor(orderId)
            : RoutePaths.workerOrderDetailFor(orderId),
      );
    }

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(title: const Text('Pembayaran QRIS')),
      body: switch (state.phase) {
        PaymentPhase.error => Center(
          child: ErrorState(
            message: 'QR pembayaran gagal dibuat. Coba lagi ya.',
            onRetry: controller.createPayment,
          ),
        ),
        PaymentPhase.paid => _PaidView(
          amount: payment?.amount,
          orderNumber: payment?.orderNumber,
          onOpenOrder: canOpenOrder ? openOrder : null,
          onDone: leave,
        ),
        PaymentPhase.expired || PaymentPhase.failed => _RetryView(
          expired: state.phase == PaymentPhase.expired,
          onRetry: controller.createPayment,
          onLater: leave,
        ),
        PaymentPhase.pending when payment != null => ListView(
          padding: const EdgeInsets.all(AppSpacing.lg),
          children: [
            QrisQrCard(payment: payment!),
            const SizedBox(height: AppSpacing.lg),
            PaymentCountdown(
              key: ValueKey(payment.id),
              expiresAt: payment.expiresAt,
              lifetime: payment.lifetime,
              onExpired: controller.checkNow,
            ),
            const SizedBox(height: AppSpacing.lg),
            Text('Arahan untuk customer', style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: AppSpacing.sm + 4),
            for (var i = 0; i < _steps.length; i++)
              Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      width: 22,
                      height: 22,
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        color: AppColors.primary.withValues(alpha: 0.3),
                        shape: BoxShape.circle,
                      ),
                      child: Text(
                        '${i + 1}',
                        style: Theme.of(context).textTheme.labelMedium,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        _steps[i],
                        style: Theme.of(context).textTheme.bodyMedium,
                      ),
                    ),
                  ],
                ),
              ),
            const SizedBox(height: AppSpacing.sm),
            OutlinedButton.icon(
              onPressed: () async {
                final changed = await controller.checkNow();
                if (!changed && context.mounted) {
                  ScaffoldMessenger.of(context)
                    ..hideCurrentSnackBar()
                    ..showSnackBar(
                      const SnackBar(
                        content: Text('Pembayaran belum kami terima.'),
                      ),
                    );
                }
              },
              icon: const Icon(Icons.refresh_rounded, size: 20),
              label: const Text('Cek status pembayaran'),
            ),
            const SizedBox(height: AppSpacing.xs),
            TextButton(
              onPressed: leave,
              child: const Text('Bayar nanti'),
            ),
            Text(
              'Pesanan tetap tersimpan. QR bisa dibuka lagi dari detail pesanan.',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: AppColors.onSurfaceVariant,
              ),
            ),
          ],
        ),
        _ => ListView(
          padding: const EdgeInsets.all(AppSpacing.lg),
          children: const [
            LoadingSkeleton(height: 380),
            SizedBox(height: AppSpacing.lg),
            LoadingSkeleton(height: 40),
          ],
        ),
      },
    );
  }
}

class _PaidView extends StatelessWidget {
  const _PaidView({
    required this.amount,
    required this.orderNumber,
    required this.onOpenOrder,
    required this.onDone,
  });

  final int? amount;
  final String? orderNumber;
  final VoidCallback? onOpenOrder;
  final VoidCallback onDone;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.check_circle_rounded, size: 72, color: AppColors.primary),
            const SizedBox(height: AppSpacing.md),
            Text('Pembayaran diterima', style: textTheme.titleLarge),
            if (orderNumber != null) ...[
              const SizedBox(height: 4),
              Text(
                orderNumber!,
                style: textTheme.bodyMedium?.copyWith(
                  color: AppColors.onSurfaceVariant,
                ),
              ),
            ],
            if (amount != null) ...[
              const SizedBox(height: AppSpacing.sm),
              Text(
                CurrencyFormatter.rupiah(amount!),
                style: textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w700),
              ),
            ],
            const SizedBox(height: AppSpacing.lg),
            if (onOpenOrder != null) ...[
              SizedBox(
                width: double.infinity,
                child: FilledButton(
                  onPressed: onOpenOrder,
                  child: const Text('Lihat pesanan'),
                ),
              ),
              const SizedBox(height: AppSpacing.sm),
            ],
            SizedBox(
              width: double.infinity,
              child: onOpenOrder != null
                  ? OutlinedButton(onPressed: onDone, child: const Text('Selesai'))
                  : FilledButton(onPressed: onDone, child: const Text('Selesai')),
            ),
          ],
        ),
      ),
    );
  }
}

class _RetryView extends StatelessWidget {
  const _RetryView({
    required this.expired,
    required this.onRetry,
    required this.onLater,
  });

  final bool expired;
  final VoidCallback onRetry;
  final VoidCallback onLater;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              expired ? Icons.timer_off_rounded : Icons.error_outline_rounded,
              size: 64,
              color: AppColors.warning,
            ),
            const SizedBox(height: AppSpacing.md),
            Text(
              expired ? 'QR sudah kedaluwarsa' : 'Pembayaran gagal',
              style: textTheme.titleLarge,
            ),
            const SizedBox(height: AppSpacing.sm),
            Text(
              'Pesanan tetap tersimpan dan belum dibayar. Buat QR baru untuk melanjutkan pembayaran.',
              textAlign: TextAlign.center,
              style: textTheme.bodyMedium?.copyWith(
                color: AppColors.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: AppSpacing.lg),
            SizedBox(
              width: double.infinity,
              child: FilledButton(
                onPressed: onRetry,
                child: const Text('Buat QR baru'),
              ),
            ),
            const SizedBox(height: AppSpacing.sm),
            TextButton(onPressed: onLater, child: const Text('Bayar nanti')),
          ],
        ),
      ),
    );
  }
}
