import 'package:flutter/material.dart';
import 'package:rijiki/core/enums/order_status.dart';
import 'package:rijiki/core/extensions/enum_ui_x.dart';
import 'package:rijiki/core/theme/app_spacing.dart';
import 'package:rijiki/features/order/domain/customer_order.dart';

class StatusChange {
  const StatusChange({required this.status, required this.notes});

  final OrderStatus status;
  final String notes;
}

Future<StatusChange?> showStatusCorrectionSheet(
  BuildContext context, {
  required CustomerOrder order,
}) {
  return showModalBottomSheet<StatusChange>(
    context: context,
    isScrollControlled: true,
    showDragHandle: true,
    builder: (_) => _StatusCorrectionSheet(order: order),
  );
}

class _StatusCorrectionSheet extends StatefulWidget {
  const _StatusCorrectionSheet({required this.order});

  final CustomerOrder order;

  @override
  State<_StatusCorrectionSheet> createState() => _StatusCorrectionSheetState();
}

class _StatusCorrectionSheetState extends State<_StatusCorrectionSheet> {
  final TextEditingController _notes = TextEditingController();
  OrderStatus? _selected;

  @override
  void dispose() {
    _notes.dispose();
    super.dispose();
  }

  bool get _canSubmit => _selected != null && _notes.text.trim().isNotEmpty;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final options = [
      for (final status in widget.order.flowStatuses)
        if (status != widget.order.status) status,
    ];

    return Padding(
      padding: EdgeInsets.fromLTRB(
        AppSpacing.lg,
        0,
        AppSpacing.lg,
        MediaQuery.viewInsetsOf(context).bottom + AppSpacing.lg,
      ),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Koreksi status', style: textTheme.titleMedium),
            const SizedBox(height: 4),
            Text(
              'Status sekarang: ${widget.order.status.label}. '
              'Koreksi tidak mewajibkan foto, tapi alasannya tercatat di riwayat.',
              style: textTheme.bodySmall,
            ),
            const SizedBox(height: AppSpacing.md),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                for (final status in options)
                  ChoiceChip(
                    label: Text(status.label),
                    selected: _selected == status,
                    onSelected: (_) => setState(() => _selected = status),
                  ),
              ],
            ),
            const SizedBox(height: AppSpacing.md),
            TextField(
              controller: _notes,
              maxLength: 300,
              maxLines: 3,
              onChanged: (_) => setState(() {}),
              decoration: const InputDecoration(
                labelText: 'Alasan koreksi (wajib)',
              ),
            ),
            const SizedBox(height: AppSpacing.sm),
            SizedBox(
              width: double.infinity,
              child: FilledButton(
                onPressed: _canSubmit
                    ? () => Navigator.pop(
                        context,
                        StatusChange(
                          status: _selected!,
                          notes: _notes.text.trim(),
                        ),
                      )
                    : null,
                child: const Text('Simpan koreksi'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
