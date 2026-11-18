import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:rijiki/app/router/route_paths.dart';
import 'package:rijiki/core/theme/app_colors.dart';
import 'package:rijiki/core/theme/app_spacing.dart';

class PaymentResultPage extends StatelessWidget {
  const PaymentResultPage({
    super.key,
    required this.orderId,
    required this.status,
  });

  final String orderId;
  final String status;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    final (IconData icon, Color color, String title, String message) =
        switch (status) {
          'paid' => (
            Icons.check_circle_rounded,
            AppColors.success,
            'Pembayaran berhasil',
            'Pesananmu kami proses. Pantau statusnya di halaman order.',
          ),
          'expired' => (
            Icons.timer_off_rounded,
            AppColors.warning,
            'QR kedaluwarsa',
            'Waktu pembayaran habis. Buat QR baru untuk melanjutkan.',
          ),
          _ => (
            Icons.error_rounded,
            AppColors.error,
            'Pembayaran gagal',
            'Pembayaran tidak berhasil diproses. Kamu bisa membuat QR baru dan mencoba lagi.',
          ),
        };
    final isPaid = status == 'paid';

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.lg),
          child: Column(
            children: [
              const Spacer(),
              Container(
                width: 96,
                height: 96,
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.14),
                  shape: BoxShape.circle,
                ),
                child: Icon(icon, size: 52, color: color),
              ),
              const SizedBox(height: AppSpacing.lg),
              Text(title, style: textTheme.headlineSmall),
              const SizedBox(height: 8),
              Text(
                message,
                textAlign: TextAlign.center,
                style: textTheme.bodyMedium?.copyWith(
                  color: AppColors.onSurfaceVariant,
                ),
              ),
              const Spacer(),
              if (isPaid)
                FilledButton(
                  onPressed: () => context.go(RoutePaths.orderDetailFor(orderId)),
                  child: const Text('Lihat order'),
                )
              else ...[
                FilledButton(
                  onPressed: () =>
                      context.pushReplacement(RoutePaths.orderPaymentFor(orderId)),
                  child: const Text('Buat QR baru'),
                ),
                const SizedBox(height: AppSpacing.sm),
                OutlinedButton(
                  onPressed: () => context.go(RoutePaths.orderDetailFor(orderId)),
                  child: const Text('Bayar nanti'),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
