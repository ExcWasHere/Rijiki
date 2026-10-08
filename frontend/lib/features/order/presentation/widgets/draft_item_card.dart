import 'package:flutter/material.dart';
import 'package:rijiki/core/theme/app_colors.dart';
import 'package:rijiki/core/theme/app_spacing.dart';
import 'package:rijiki/core/utils/currency_formatter.dart';
import 'package:rijiki/features/order/domain/new_order.dart';
import 'package:rijiki/features/order/presentation/widgets/quantity_stepper.dart';
import 'package:rijiki/features/order/presentation/widgets/shoe_condition_notes_field.dart';
import 'package:rijiki/features/service/domain/care_service.dart';
import 'package:rijiki/shared/widgets/app_card.dart';

class DraftItemCard extends StatefulWidget {
  const DraftItemCard({
    super.key,
    required this.item,
    required this.index,
    required this.canRemove,
    required this.onBrandChanged,
    required this.onQuantityChanged,
    required this.onNotesChanged,
    required this.onPickService,
    required this.onRemove,
  });

  final OrderDraftItem item;
  final int index;
  final bool canRemove;
  final ValueChanged<String> onBrandChanged;
  final ValueChanged<int> onQuantityChanged;
  final ValueChanged<String> onNotesChanged;
  final VoidCallback onPickService;
  final VoidCallback onRemove;

  @override
  State<DraftItemCard> createState() => _DraftItemCardState();
}

class _DraftItemCardState extends State<DraftItemCard> {
  late final TextEditingController _brand = TextEditingController(
    text: widget.item.shoeBrand,
  );
  late final TextEditingController _notes = TextEditingController(
    text: widget.item.notes,
  );

  @override
  void dispose() {
    _brand.dispose();
    _notes.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final CareService? service = widget.item.service;

    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  'Sepatu ${widget.index + 1}',
                  style: textTheme.titleSmall,
                ),
              ),
              if (widget.canRemove)
                IconButton(
                  onPressed: widget.onRemove,
                  icon: const Icon(Icons.delete_outline_rounded),
                  tooltip: 'Hapus sepatu',
                  visualDensity: VisualDensity.compact,
                ),
            ],
          ),
          const SizedBox(height: AppSpacing.sm),
          TextField(
            controller: _brand,
            onChanged: widget.onBrandChanged,
            textCapitalization: TextCapitalization.words,
            decoration: const InputDecoration(
              labelText: 'Merk sepatu',
              hintText: 'Mis. Nike Air Force 1',
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          Row(
            children: [
              Expanded(child: Text('Jumlah', style: textTheme.bodyMedium)),
              QuantityStepper(
                value: widget.item.quantity,
                onChanged: widget.onQuantityChanged,
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          InkWell(
            onTap: widget.onPickService,
            borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.md,
                vertical: 12,
              ),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
                border: Border.all(color: AppColors.outline),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: service == null
                        ? Text(
                            'Pilih layanan',
                            style: textTheme.bodyLarge?.copyWith(
                              color: AppColors.onSurfaceVariant,
                            ),
                          )
                        : Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(service.name, style: textTheme.titleSmall),
                              Text(
                                '${CurrencyFormatter.rupiah(service.basePrice)} / pasang',
                                style: textTheme.bodySmall?.copyWith(
                                  color: AppColors.onSurfaceVariant,
                                ),
                              ),
                            ],
                          ),
                  ),
                  const Icon(
                    Icons.keyboard_arrow_down_rounded,
                    color: AppColors.onSurfaceVariant,
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          ShoeConditionNotesField(
            controller: _notes,
            onChanged: widget.onNotesChanged,
          ),
          if (service != null) ...[
            const SizedBox(height: 4),
            Align(
              alignment: Alignment.centerRight,
              child: Text(
                CurrencyFormatter.rupiah(widget.item.lineTotal),
                style: textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}
