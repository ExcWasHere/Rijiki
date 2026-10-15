import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:rijiki/core/theme/app_colors.dart';
import 'package:rijiki/core/theme/app_spacing.dart';
import 'package:rijiki/features/finance/domain/expense_draft_item.dart';
import 'package:rijiki/features/finance/presentation/utils/finance_format.dart';
import 'package:rijiki/features/finance/presentation/utils/rupiah_input_formatter.dart';
import 'package:rijiki/features/finance/presentation/widgets/expense_type_selector.dart';

class ExpenseDraftItemCard extends StatefulWidget {
  const ExpenseDraftItemCard({
    super.key,
    required this.item,
    required this.onChanged,
    required this.onRemove,
    this.canRemove = true,
  });

  final ExpenseDraftItem item;
  final ValueChanged<ExpenseDraftItem> onChanged;
  final VoidCallback onRemove;
  final bool canRemove;

  @override
  State<ExpenseDraftItemCard> createState() => _ExpenseDraftItemCardState();
}

class _ExpenseDraftItemCardState extends State<ExpenseDraftItemCard> {
  late final TextEditingController _name;
  late final TextEditingController _amount;
  late final TextEditingController _quantity;
  late final TextEditingController _unit;
  late final TextEditingController _vendor;
  late bool _expanded;

  ExpenseDraftItem get _item => widget.item;

  @override
  void initState() {
    super.initState();
    final item = widget.item;
    _name = TextEditingController(text: item.itemName);
    _amount = TextEditingController(text: rupiahInputText(item.amount));
    _quantity = TextEditingController(
      text: item.quantity == null ? '' : _quantityText(item.quantity!),
    );
    _unit = TextEditingController(text: item.unit ?? '');
    _vendor = TextEditingController(text: item.vendorName ?? '');
    _expanded =
        item.quantity != null || item.unit != null || item.vendorName != null;
  }

  @override
  void dispose() {
    _name.dispose();
    _amount.dispose();
    _quantity.dispose();
    _unit.dispose();
    _vendor.dispose();
    super.dispose();
  }

  static String _quantityText(double value) => value == value.roundToDouble()
      ? value.toInt().toString()
      : value.toString().replaceAll('.', ',');

  Future<void> _pickDate() async {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final picked = await showDatePicker(
      context: context,
      initialDate: _item.transactionDate.isAfter(today)
          ? today
          : _item.transactionDate,
      firstDate: DateTime(today.year - 2),
      lastDate: today,
    );
    if (picked != null) {
      widget.onChanged(_item.copyWith(transactionDate: picked));
    }
  }

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final review = _item.needsReview;

    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
        border: Border.all(
          color: review
              ? AppColors.warning
              : AppColors.outline.withValues(alpha: 0.3),
          width: review ? 1.5 : 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: TextField(
                  controller: _name,
                  textCapitalization: TextCapitalization.sentences,
                  decoration: const InputDecoration(
                    labelText: 'Nama barang',
                    isDense: true,
                  ),
                  onChanged: (value) =>
                      widget.onChanged(_item.copyWith(itemName: value)),
                ),
              ),
              if (widget.canRemove)
                IconButton(
                  tooltip: 'Hapus item',
                  onPressed: widget.onRemove,
                  icon: const Icon(Icons.delete_outline_rounded),
                  color: AppColors.onSurfaceVariant,
                ),
            ],
          ),
          if (review) ...[
            const SizedBox(height: AppSpacing.sm + 4),
            Container(
              padding: const EdgeInsets.fromLTRB(12, 8, 4, 8),
              decoration: BoxDecoration(
                color: AppColors.warning.withValues(alpha: 0.14),
                borderRadius: BorderRadius.circular(AppSpacing.radiusMd - 2),
              ),
              child: Row(
                children: [
                  const Icon(
                    Icons.error_outline_rounded,
                    size: AppSpacing.iconSm,
                    color: AppColors.warning,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Perlu dicek: AI kurang yakin soal tipe atau nominalnya.',
                      style: textTheme.bodySmall,
                    ),
                  ),
                  TextButton(
                    onPressed: () =>
                        widget.onChanged(_item.copyWith(needsReview: false)),
                    child: const Text('Sudah benar'),
                  ),
                ],
              ),
            ),
          ],
          const SizedBox(height: AppSpacing.md),
          TextField(
            controller: _amount,
            keyboardType: TextInputType.number,
            inputFormatters: const [RupiahInputFormatter()],
            decoration: const InputDecoration(
              labelText: 'Nominal',
              prefixText: 'Rp ',
              isDense: true,
            ),
            onChanged: (value) => widget.onChanged(
              _item.copyWith(amount: parseRupiahInput(value)),
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          Text(
            'Tipe pengeluaran',
            style: textTheme.labelLarge?.copyWith(
              color: AppColors.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
          ExpenseTypeSelector(
            selected: _item.expenseType,
            onChanged: (type) => widget.onChanged(
              _item.copyWith(expenseType: type, needsReview: false),
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
          InkWell(
            borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
            onTap: () => setState(() => _expanded = !_expanded),
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 6),
              child: Row(
                children: [
                  Text(
                    'Detail barang',
                    style: textTheme.labelLarge?.copyWith(
                      color: AppColors.primaryDark,
                    ),
                  ),
                  const SizedBox(width: 4),
                  Icon(
                    _expanded
                        ? Icons.expand_less_rounded
                        : Icons.expand_more_rounded,
                    size: AppSpacing.iconSm + 2,
                    color: AppColors.primaryDark,
                  ),
                ],
              ),
            ),
          ),
          AnimatedSize(
            duration: const Duration(milliseconds: 200),
            curve: Curves.easeOutCubic,
            alignment: Alignment.topCenter,
            child: _expanded ? _details() : const SizedBox(width: double.infinity),
          ),
        ],
      ),
    );
  }

  Widget _details() {
    return Padding(
      padding: const EdgeInsets.only(top: AppSpacing.sm),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _quantity,
                  keyboardType: const TextInputType.numberWithOptions(
                    decimal: true,
                  ),
                  inputFormatters: [
                    FilteringTextInputFormatter.allow(RegExp(r'[0-9.,]')),
                  ],
                  decoration: const InputDecoration(
                    labelText: 'Jumlah',
                    isDense: true,
                  ),
                  onChanged: (value) {
                    final parsed = double.tryParse(value.replaceAll(',', '.'));
                    widget.onChanged(
                      parsed == null
                          ? _item.copyWith(clearQuantity: true)
                          : _item.copyWith(quantity: parsed),
                    );
                  },
                ),
              ),
              const SizedBox(width: AppSpacing.sm + 4),
              Expanded(
                child: TextField(
                  controller: _unit,
                  decoration: const InputDecoration(
                    labelText: 'Satuan',
                    isDense: true,
                  ),
                  onChanged: (value) =>
                      widget.onChanged(_item.copyWith(unit: value.trim())),
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.sm + 4),
          TextField(
            controller: _vendor,
            textCapitalization: TextCapitalization.words,
            decoration: const InputDecoration(
              labelText: 'Toko / penyedia',
              isDense: true,
            ),
            onChanged: (value) =>
                widget.onChanged(_item.copyWith(vendorName: value.trim())),
          ),
          const SizedBox(height: AppSpacing.sm + 4),
          InkWell(
            borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
            onTap: _pickDate,
            child: InputDecorator(
              decoration: const InputDecoration(
                labelText: 'Tanggal',
                isDense: true,
                suffixIcon: Icon(Icons.calendar_month_rounded),
              ),
              child: Text(formatDate(_item.transactionDate)),
            ),
          ),
        ],
      ),
    );
  }
}
