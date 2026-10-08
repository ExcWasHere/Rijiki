import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:rijiki/app/router/route_paths.dart';
import 'package:rijiki/core/theme/app_colors.dart';
import 'package:rijiki/core/theme/app_spacing.dart';
import 'package:rijiki/features/payment/presentation/controllers/payment_controller.dart';
import 'package:rijiki/features/payment/presentation/widgets/payment_countdown.dart';
import 'package:rijiki/features/payment/presentation/widgets/qris_qr_card.dart';
import 'package:rijiki/shared/widgets/error_state.dart';
import 'package:rijiki/shared/widgets/loading_skeleton.dart';

class QrisPaymentPage extends ConsumerWidget {
  const QrisPaymentPage({super.key, required this.orderId});

  final String orderId;

  static const List<String> _steps = [
    'Buka e-wallet atau mobile banking apa pun.',
    'Pilih menu scan QR, lalu arahkan ke kode di atas.',
    'Periksa nominal, lalu konfirmasi pembayaran.',
  ];

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final provider = paymentControllerProvider(orderId);

    ref.listen(provider, (previous, next) {
      final result = switch (next.phase) {
        PaymentPhase.paid => 'paid',
        PaymentPhase.failed => 'failed',
        PaymentPhase.expired => 'expired',
        _ => null,
      };
      if (result != null) {
        context.pushReplacement(RoutePaths.paymentResultFor(orderId, result));
      }
    });

    final state = ref.watch(provider);
    final controller = ref.read(provider.notifier);
    final payment = state.payment;
    final textTheme = Theme.of(context).textTheme;

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
        PaymentPhase.pending when payment != null => ListView(
          padding: const EdgeInsets.all(AppSpacing.lg),
          children: [
            QrisQrCard(payment: payment!),
            const SizedBox(height: AppSpacing.lg),
            PaymentCountdown(
              key: ValueKey(payment!.id),
              expiresAt: payment!.expiresAt,
              lifetime: payment!.lifetime,
              onExpired: controller.checkNow,
            ),
            const SizedBox(height: AppSpacing.lg),
            Text('Cara membayar', style: textTheme.titleMedium),
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
                      child: Text('${i + 1}', style: textTheme.labelMedium),
                    ),
                    const SizedBox(width: 12),
                    Expanded(child: Text(_steps[i], style: textTheme.bodyMedium)),
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
            const SizedBox(height: AppSpacing.sm),
            Text(
              'Status diperbarui otomatis setelah kamu membayar.',
              textAlign: TextAlign.center,
              style: textTheme.bodySmall?.copyWith(
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
