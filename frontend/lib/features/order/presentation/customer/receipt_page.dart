import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:rijiki/core/session/session_provider.dart';
import 'package:rijiki/core/theme/app_colors.dart';
import 'package:rijiki/core/theme/app_spacing.dart';
import 'package:rijiki/features/order/presentation/controllers/order_detail_controller.dart';
import 'package:rijiki/features/order/presentation/widgets/receipt_card.dart';
import 'package:rijiki/shared/widgets/error_state.dart';
import 'package:rijiki/shared/widgets/loading_skeleton.dart';

class ReceiptPage extends ConsumerWidget {
  const ReceiptPage({super.key, required this.orderId});

  final String orderId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final order = ref.watch(orderDetailProvider(orderId));
    final user = ref.watch(sessionProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(title: const Text('Struk digital')),
      body: order.when(
        loading: () => ListView(
          padding: const EdgeInsets.all(AppSpacing.lg),
          children: const [LoadingSkeleton(height: 480)],
        ),
        error: (_, _) => Center(
          child: ErrorState(
            message: 'Struk gagal dimuat. Coba lagi ya.',
            onRetry: () => ref.invalidate(orderDetailProvider(orderId)),
          ),
        ),
        data: (data) => ListView(
          padding: const EdgeInsets.all(AppSpacing.lg),
          children: [
            ReceiptCard(
              order: data,
              customerName: data.customerName ?? user?.fullName ?? '-',
              customerPhone: data.customerPhone ?? user?.phoneNumber ?? '-',
            ),
            const SizedBox(height: AppSpacing.md),
            OutlinedButton.icon(
              onPressed: () async {
                await Clipboard.setData(ClipboardData(text: data.orderNumber));
                if (!context.mounted) return;
                ScaffoldMessenger.of(context)
                  ..hideCurrentSnackBar()
                  ..showSnackBar(
                    const SnackBar(content: Text('Nomor order disalin.')),
                  );
              },
              icon: const Icon(Icons.copy_rounded, size: 20),
              label: const Text('Salin nomor order'),
            ),
          ],
        ),
      ),
    );
  }
}
