import 'package:flutter/material.dart';
import 'package:rijiki/core/theme/app_colors.dart';
import 'package:rijiki/core/theme/app_spacing.dart';
import 'package:rijiki/features/order/domain/applied_promo.dart';
import 'package:rijiki/features/order/presentation/controllers/order_create_controller.dart';

/// Input kode promo yang bisa digabung: maksimal 1 promo layanan + 1 promo
/// ongkir. Promo yang sudah dipakai tampil sebagai kartu dengan tombol hapus.
class PromoCodeField extends StatefulWidget {
  const PromoCodeField({
    super.key,
    required this.promo,
    required this.onApply,
    required this.onRemove,
  });

  final PromoUiState promo;

  /// Mengembalikan true bila kode diterima (kolom input dikosongkan).
  final Future<bool> Function(String code) onApply;
  final ValueChanged<String> onRemove;

  @override
  State<PromoCodeField> createState() => _PromoCodeFieldState();
}

class _PromoCodeFieldState extends State<PromoCodeField> {
  final TextEditingController _controller = TextEditingController();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _apply() async {
    final accepted = await widget.onApply(_controller.text);
    if (accepted && mounted) _controller.clear();
  }

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final promo = widget.promo;
    final checking = promo.isChecking;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        for (final applied in promo.applied) ...[
          _AppliedPromoTile(
            promo: applied,
            onRemove: checking ? null : () => widget.onRemove(applied.code),
          ),
          const SizedBox(height: AppSpacing.sm),
        ],
        if (promo.canAddMore)
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: TextField(
                  controller: _controller,
                  enabled: !checking,
                  textCapitalization: TextCapitalization.characters,
                  textInputAction: TextInputAction.done,
                  onSubmitted: (_) => _apply(),
                  decoration: InputDecoration(
                    hintText: promo.applied.isEmpty
                        ? 'Masukkan kode promo'
                        : 'Tambah kode promo lain',
                    errorText: promo.error,
                    errorMaxLines: 3,
                  ),
                ),
              ),
              const SizedBox(width: 10),
              SizedBox(
                height: 52,
                child: FilledButton(
                  onPressed: checking ? null : _apply,
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
          ),
        const SizedBox(height: 6),
        Text(
          'Bisa gabung 1 promo layanan dan 1 promo ongkir.',
          style: textTheme.bodySmall?.copyWith(
            color: AppColors.onSurfaceVariant,
          ),
        ),
      ],
    );
  }
}

class _AppliedPromoTile extends StatelessWidget {
  const _AppliedPromoTile({required this.promo, required this.onRemove});

  final AppliedPromo promo;
  final VoidCallback? onRemove;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return Container(
      padding: const EdgeInsets.fromLTRB(12, 10, 4, 10),
      decoration: BoxDecoration(
        color: AppColors.success.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
        border: Border.all(color: AppColors.success.withValues(alpha: 0.5)),
      ),
      child: Row(
        children: [
          Icon(
            promo.appliesToShipping
                ? Icons.local_shipping_outlined
                : Icons.local_offer_rounded,
            size: 20,
            color: AppColors.success,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(promo.code, style: textTheme.titleSmall),
                if (promo.description != null)
                  Text(promo.description!, style: textTheme.bodySmall),
              ],
            ),
          ),
          TextButton(onPressed: onRemove, child: const Text('Hapus')),
        ],
      ),
    );
  }
}
