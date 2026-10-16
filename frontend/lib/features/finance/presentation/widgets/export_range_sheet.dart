import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:rijiki/core/enums/expense_type.dart';
import 'package:rijiki/core/theme/app_colors.dart';
import 'package:rijiki/core/theme/app_spacing.dart';
import 'package:rijiki/core/utils/rupiah_formatter.dart';
import 'package:rijiki/features/finance/domain/finance_export.dart';
import 'package:rijiki/features/finance/presentation/controllers/finance_export_controller.dart';
import 'package:rijiki/features/finance/presentation/expense_type_ui.dart';
import 'package:rijiki/features/finance/presentation/utils/finance_format.dart';
import 'package:rijiki/shared/widgets/loading_skeleton.dart';

Future<void> showExportRangeSheet(
  BuildContext context, {
  DateTimeRange? initialRange,
  ExpenseType? initialExpenseType,
}) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    showDragHandle: true,
    backgroundColor: AppColors.surface,
    builder: (_) => _ExportRangeSheet(
      initialRange: initialRange,
      initialExpenseType: initialExpenseType,
    ),
  );
}

enum _Preset {
  thisMonth('Bulan ini'),
  lastMonth('Bulan lalu'),
  last30Days('30 hari terakhir'),
  custom('Rentang sendiri');

  const _Preset(this.label);

  final String label;
}

DateTime _today() {
  final now = DateTime.now();
  return DateTime(now.year, now.month, now.day);
}

DateTimeRange _rangeFor(_Preset preset) {
  final today = _today();
  return switch (preset) {
    _Preset.thisMonth => DateTimeRange(
      start: DateTime(today.year, today.month, 1),
      end: today,
    ),
    _Preset.lastMonth => DateTimeRange(
      start: DateTime(today.year, today.month - 1, 1),
      end: DateTime(today.year, today.month, 0),
    ),
    _Preset.last30Days => DateTimeRange(
      start: DateTime(today.year, today.month, today.day - 29),
      end: today,
    ),
    _Preset.custom => DateTimeRange(start: today, end: today),
  };
}

class _ExportRangeSheet extends ConsumerStatefulWidget {
  const _ExportRangeSheet({this.initialRange, this.initialExpenseType});

  final DateTimeRange? initialRange;
  final ExpenseType? initialExpenseType;

  @override
  ConsumerState<_ExportRangeSheet> createState() => _ExportRangeSheetState();
}

class _ExportRangeSheetState extends ConsumerState<_ExportRangeSheet> {
  late _Preset _preset;
  late DateTime _start;
  late DateTime _end;
  ExpenseType? _type;

  @override
  void initState() {
    super.initState();
    final initial = widget.initialRange;
    if (initial != null) {
      _preset = _Preset.custom;
      _start = DateTime(initial.start.year, initial.start.month, initial.start.day);
      _end = DateTime(initial.end.year, initial.end.month, initial.end.day);
    } else {
      _preset = _Preset.thisMonth;
      final range = _rangeFor(_preset);
      _start = range.start;
      _end = range.end;
    }
    _type = widget.initialExpenseType;
  }

  void _optionsChanged() {
    final notifier = ref.read(exportActionProvider.notifier);
    if (ref.read(exportActionProvider).status == ExportStatus.failure) {
      notifier.reset();
    }
  }

  Future<void> _selectPreset(_Preset preset) async {
    if (preset == _Preset.custom) {
      final today = _today();
      final picked = await showDateRangePicker(
        context: context,
        firstDate: DateTime(today.year - 2),
        lastDate: today,
        initialDateRange: DateTimeRange(start: _start, end: _end),
        helpText: 'Pilih rentang tanggal',
        saveText: 'Terapkan',
      );
      if (picked == null || !mounted) return;
      setState(() {
        _preset = preset;
        _start = DateTime(picked.start.year, picked.start.month, picked.start.day);
        _end = DateTime(picked.end.year, picked.end.month, picked.end.day);
      });
    } else {
      final range = _rangeFor(preset);
      setState(() {
        _preset = preset;
        _start = range.start;
        _end = range.end;
      });
    }
    _optionsChanged();
  }

  void _selectType(ExpenseType? type) {
    setState(() => _type = type);
    _optionsChanged();
  }

  @override
  Widget build(BuildContext context) {
    final export = ref.watch(exportActionProvider);
    final bottomInset = MediaQuery.viewInsetsOf(context).bottom;

    return SafeArea(
      child: AnimatedPadding(
        duration: const Duration(milliseconds: 150),
        padding: EdgeInsets.only(bottom: bottomInset),
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(
            AppSpacing.lg,
            0,
            AppSpacing.lg,
            AppSpacing.lg,
          ),
          child: AnimatedSwitcher(
            duration: const Duration(milliseconds: 220),
            child: export.status == ExportStatus.success
                ? _SuccessView(
                    key: const ValueKey('success'),
                    result: export.result!,
                    start: _start,
                    end: _end,
                  )
                : _OptionsView(
                    key: const ValueKey('options'),
                    preset: _preset,
                    start: _start,
                    end: _end,
                    type: _type,
                    export: export,
                    onPreset: _selectPreset,
                    onType: _selectType,
                  ),
          ),
        ),
      ),
    );
  }
}

class _OptionsView extends ConsumerWidget {
  const _OptionsView({
    super.key,
    required this.preset,
    required this.start,
    required this.end,
    required this.type,
    required this.export,
    required this.onPreset,
    required this.onType,
  });

  final _Preset preset;
  final DateTime start;
  final DateTime end;
  final ExpenseType? type;
  final ExportState export;
  final ValueChanged<_Preset> onPreset;
  final ValueChanged<ExpenseType?> onType;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final textTheme = Theme.of(context).textTheme;
    final query = FinanceExportQuery(start: start, end: end, expenseType: type);
    final preview = ref.watch(exportPreviewProvider(query));
    final exporting = export.isExporting;
    final canExport = !exporting && (preview.value?.count ?? 0) > 0;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Ekspor ke Excel', style: textTheme.titleLarge),
        const SizedBox(height: 2),
        Text(
          'Pilih rentang tanggal laporan.',
          style: textTheme.bodyMedium?.copyWith(
            color: AppColors.onSurfaceVariant,
          ),
        ),
        const SizedBox(height: AppSpacing.md),
        Wrap(
          spacing: AppSpacing.sm,
          runSpacing: AppSpacing.sm,
          children: [
            for (final p in _Preset.values)
              _OptionChip(
                label: p.label,
                icon: p == _Preset.custom ? Icons.edit_calendar_rounded : null,
                selected: p == preset,
                onTap: exporting ? null : () => onPreset(p),
              ),
          ],
        ),
        const SizedBox(height: AppSpacing.sm + 4),
        Row(
          children: [
            const Icon(
              Icons.calendar_month_rounded,
              size: AppSpacing.iconSm,
              color: AppColors.primaryDark,
            ),
            const SizedBox(width: 6),
            Text(
              formatDateRange(start, end),
              style: textTheme.titleSmall,
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.lg - 4),
        Text(
          'Isi laporan',
          style: textTheme.labelLarge?.copyWith(
            color: AppColors.onSurfaceVariant,
          ),
        ),
        const SizedBox(height: AppSpacing.sm),
        Wrap(
          spacing: AppSpacing.sm,
          runSpacing: AppSpacing.sm,
          children: [
            _OptionChip(
              label: 'Semua transaksi',
              selected: type == null,
              onTap: exporting ? null : () => onType(null),
            ),
            for (final t in ExpenseType.values)
              _OptionChip(
                label: t.label,
                icon: t.icon,
                accent: t.color,
                selected: type == t,
                onTap: exporting ? null : () => onType(t),
              ),
          ],
        ),
        if (type != null) ...[
          const SizedBox(height: 6),
          Text(
            'Hanya pengeluaran bertipe ${type!.label} yang diekspor.',
            style: textTheme.bodySmall?.copyWith(
              color: AppColors.onSurfaceVariant,
            ),
          ),
        ],
        const SizedBox(height: AppSpacing.md),
        preview.when(
          data: (p) => _PreviewCard(preview: p, onlyExpense: type != null),
          loading: () => const LoadingSkeleton(
            height: 84,
            radius: AppSpacing.radiusLg,
          ),
          error: (_, _) => Text(
            'Gagal menghitung pratinjau.',
            style: textTheme.bodyMedium?.copyWith(color: AppColors.error),
          ),
        ),
        if (export.status == ExportStatus.failure) ...[
          const SizedBox(height: AppSpacing.sm + 4),
          Row(
            children: [
              const Icon(
                Icons.error_outline_rounded,
                size: AppSpacing.iconSm,
                color: AppColors.error,
              ),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  export.errorMessage ?? 'Ekspor gagal.',
                  style: textTheme.bodySmall?.copyWith(color: AppColors.error),
                ),
              ),
            ],
          ),
        ],
        const SizedBox(height: AppSpacing.md),
        FilledButton.icon(
          onPressed: canExport
              ? () => ref.read(exportActionProvider.notifier).run(query)
              : null,
          icon: exporting
              ? const SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: AppColors.onPrimary,
                  ),
                )
              : const Icon(Icons.file_download_outlined, size: 20),
          label: Text(
            exporting
                ? 'Menyiapkan file...'
                : (export.status == ExportStatus.failure
                      ? 'Coba lagi'
                      : 'Ekspor'),
          ),
        ),
      ],
    );
  }
}

class _PreviewCard extends StatelessWidget {
  const _PreviewCard({required this.preview, required this.onlyExpense});

  final ExportPreview preview;
  final bool onlyExpense;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: AppColors.background,
        borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
        border: Border.all(color: AppColors.outline.withValues(alpha: 0.3)),
      ),
      child: preview.count == 0
          ? Row(
              children: [
                const Icon(
                  Icons.info_outline_rounded,
                  size: AppSpacing.iconSm + 2,
                  color: AppColors.onSurfaceVariant,
                ),
                const SizedBox(width: AppSpacing.sm),
                Expanded(
                  child: Text(
                    'Tidak ada transaksi di rentang ini.',
                    style: textTheme.bodyMedium?.copyWith(
                      color: AppColors.onSurfaceVariant,
                    ),
                  ),
                ),
              ],
            )
          : Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('${preview.count} transaksi akan diekspor',
                    style: textTheme.titleSmall),
                const SizedBox(height: AppSpacing.sm),
                Row(
                  children: [
                    if (!onlyExpense) ...[
                      Expanded(
                        child: _Total(
                          label: 'Pemasukan',
                          value: preview.income,
                          color: AppColors.success,
                        ),
                      ),
                      const SizedBox(width: AppSpacing.md),
                    ],
                    Expanded(
                      child: _Total(
                        label: 'Pengeluaran',
                        value: preview.expense,
                        color: AppColors.rijikiOrange,
                      ),
                    ),
                  ],
                ),
              ],
            ),
    );
  }
}

class _Total extends StatelessWidget {
  const _Total({required this.label, required this.value, required this.color});

  final String label;
  final double value;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: textTheme.bodySmall?.copyWith(
            color: AppColors.onSurfaceVariant,
          ),
        ),
        Text(
          RupiahFormatter.compact(value),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: textTheme.titleSmall?.copyWith(
            color: color,
            fontWeight: FontWeight.w700,
          ),
        ),
      ],
    );
  }
}

class _SuccessView extends StatelessWidget {
  const _SuccessView({
    super.key,
    required this.result,
    required this.start,
    required this.end,
  });

  final FinanceExportResult result;
  final DateTime start;
  final DateTime end;

  static const String _demoNote =
      'Fase UI: file asli nanti dibuat oleh backend.';

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return Column(
      children: [
        const SizedBox(height: AppSpacing.sm),
        Container(
          width: 56,
          height: 56,
          decoration: BoxDecoration(
            color: AppColors.success.withValues(alpha: 0.14),
            shape: BoxShape.circle,
          ),
          child: const Icon(
            Icons.check_rounded,
            size: AppSpacing.iconLg,
            color: AppColors.success,
          ),
        ),
        const SizedBox(height: AppSpacing.md),
        Text('File siap diekspor', style: textTheme.titleLarge),
        const SizedBox(height: 6),
        Text(
          result.fileName,
          textAlign: TextAlign.center,
          style: textTheme.titleSmall,
        ),
        const SizedBox(height: 4),
        Text(
          '${result.transactionCount} transaksi · ${formatDateRange(start, end)}',
          textAlign: TextAlign.center,
          style: textTheme.bodyMedium?.copyWith(
            color: AppColors.onSurfaceVariant,
          ),
        ),
        const SizedBox(height: AppSpacing.sm),
        Text(
          _demoNote,
          textAlign: TextAlign.center,
          style: textTheme.bodySmall?.copyWith(
            color: AppColors.onSurfaceVariant,
          ),
        ),
        const SizedBox(height: AppSpacing.lg),
        FilledButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Selesai'),
        ),
      ],
    );
  }
}

class _OptionChip extends StatelessWidget {
  const _OptionChip({
    required this.label,
    required this.selected,
    required this.onTap,
    this.icon,
    this.accent,
  });

  final String label;
  final bool selected;
  final VoidCallback? onTap;
  final IconData? icon;
  final Color? accent;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final color = accent ?? AppColors.primaryDark;

    return ChoiceChip(
      selected: selected,
      onSelected: onTap == null ? null : (_) => onTap!(),
      showCheckmark: false,
      avatar: icon == null ? null : Icon(icon, size: 16, color: color),
      label: Text(label),
      labelStyle: textTheme.labelLarge?.copyWith(
        color: selected ? AppColors.onSurface : AppColors.onSurfaceVariant,
        fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
      ),
      backgroundColor: AppColors.surface,
      selectedColor: color.withValues(alpha: 0.18),
      shape: const StadiumBorder(),
      side: BorderSide(
        color: selected ? color : AppColors.outline.withValues(alpha: 0.4),
      ),
    );
  }
}
