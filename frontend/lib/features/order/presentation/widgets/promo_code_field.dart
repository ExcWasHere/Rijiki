import 'package:flutter/material.dart';
import 'package:rijiki/core/theme/app_colors.dart';
import 'package:rijiki/core/theme/app_spacing.dart';
import 'package:rijiki/features/order/presentation/controllers/order_create_controller.dart';

class PromoCodeField extends StatefulWidget {
  const PromoCodeField({
    super.key,
    required this.promo,
    required this.onApply,
    required this.onClear,
  });

  final PromoUiState promo;
  final ValueChanged<String> onApply;
  final VoidCallback onClear;

  @override
  State<PromoCodeField> createState() => _PromoCodeFieldState();
}

class _PromoCodeFieldState extends State<PromoCodeField> {
  late final TextEditingController _controller = TextEditingController(
    text: widget.promo.code ?? '',
  );

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final promo = widget.promo;

    if (promo.status == PromoStatus.applied) {
      return Container(
        padding: const EdgeInsets.fromLTRB(12, 10, 4, 10),
        decoration: BoxDecoration(
          color: AppColors.success.withValues(alpha: 0.10),
          borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
          border: Border.all(color: AppColors.success.withValues(alpha: 0.5)),
        ),
        child: Row(
          children: [
            const Icon(
              Icons.local_offer_rounded,
              size: 20,
              color: AppColors.success,
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(promo.code ?? '', style: textTheme.titleSmall),
                  if (promo.description != null)
                    Text(promo.description!, style: textTheme.bodySmall),
                ],
              ),
            ),
            TextButton(
              onPressed: () {
                _controller.clear();
                widget.onClear();
              },
              child: const Text('Hapus'),
            ),
          ],
        ),
      );
    }

    final checking = promo.status == PromoStatus.checking;

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: TextField(
            controller: _controller,
            enabled: !checking,
            textCapitalization: TextCapitalization.characters,
            textInputAction: TextInputAction.done,
            onSubmitted: widget.onApply,
            decoration: InputDecoration(
              hintText: 'Masukkan kode promo',
              errorText: promo.status == PromoStatus.invalid
                  ? promo.error
                  : null,
              errorMaxLines: 2,
            ),
          ),
        ),
        const SizedBox(width: 10),
        SizedBox(
          height: 52,
          child: FilledButton(
            onPressed: checking ? null : () => widget.onApply(_controller.text),
            style: FilledButton.styleFrom(
              minimumSize: const Size(72, 52),
              padding: const EdgeInsets.symmetric(horizontal: 16),
            ),
            child: checking
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(
                      strokeWidth: 2.2,
                      color: AppColors.onPrimary,
                    ),
                  )
                : const Text('Pakai'),
          ),
        ),
      ],
    );
  }
}
