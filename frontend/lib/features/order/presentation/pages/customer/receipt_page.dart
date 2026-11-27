import 'package:flutter/foundation.dart' show debugPrint;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:rijiki/core/session/session_provider.dart';
import 'package:rijiki/core/theme/app_colors.dart';
import 'package:rijiki/core/theme/app_spacing.dart';
import 'package:rijiki/features/order/domain/customer_order.dart';
import 'package:rijiki/features/order/presentation/controllers/order_detail_controller.dart';
import 'package:rijiki/features/order/presentation/utils/receipt_pdf.dart';
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
        data: (data) {
          final name = data.customerName ?? user?.fullName ?? '-';
          final phone = data.customerPhone ?? user?.phoneNumber ?? '-';

          return ListView(
            padding: const EdgeInsets.all(AppSpacing.lg),
            children: [
              ReceiptCard(
                order: data,
                customerName: name,
                customerPhone: phone,
              ),
              const SizedBox(height: AppSpacing.md),
              _SharePdfButton(
                order: data,
                customerName: name,
                customerPhone: phone,
              ),
              const SizedBox(height: AppSpacing.sm),
              OutlinedButton.icon(
                onPressed: () async {
                  await Clipboard.setData(
                    ClipboardData(text: data.orderNumber),
                  );
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
          );
        },
      ),
    );
  }
}

class _SharePdfButton extends StatefulWidget {
  const _SharePdfButton({
    required this.order,
    required this.customerName,
    required this.customerPhone,
  });

  final CustomerOrder order;
  final String customerName;
  final String customerPhone;

  @override
  State<_SharePdfButton> createState() => _SharePdfButtonState();
}

class _SharePdfButtonState extends State<_SharePdfButton> {
  bool _busy = false;

  Future<void> _share() async {
    if (_busy) return;
    final box = context.findRenderObject() as RenderBox?;
    final origin = box == null ? null : box.localToGlobal(Offset.zero) & box.size;
    final messenger = ScaffoldMessenger.of(context);

    setState(() => _busy = true);
    try {
      await ReceiptPdf.share(
        order: widget.order,
        customerName: widget.customerName,
        customerPhone: widget.customerPhone,
        sharePositionOrigin: origin,
      );
    } catch (e) {
      debugPrint('[ReceiptPdf] gagal membuat atau membagikan PDF: $e');
      messenger
        ..hideCurrentSnackBar()
        ..showSnackBar(
          const SnackBar(
            content: Text('Struk belum bisa dibuat. Coba lagi ya.'),
          ),
        );
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return FilledButton.icon(
      onPressed: _busy ? null : _share,
      icon: _busy
          ? const SizedBox(
              width: 18,
              height: 18,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                color: AppColors.onPrimary,
              ),
            )
          : const Icon(Icons.picture_as_pdf_rounded, size: 20),
      label: const Text('Bagikan sebagai PDF'),
    );
  }
}
