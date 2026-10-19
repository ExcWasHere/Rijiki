import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:rijiki/core/enums/discount_type.dart';
import 'package:rijiki/core/theme/app_colors.dart';
import 'package:rijiki/core/theme/app_spacing.dart';
import 'package:rijiki/core/utils/rupiah_input_formatter.dart';
import 'package:rijiki/features/cms/presentation/controllers/promo_manage_controller.dart';
import 'package:rijiki/features/cms/presentation/utils/promo_format.dart';
import 'package:rijiki/features/cms/presentation/widgets/active_toggle_tile.dart';
import 'package:rijiki/features/cms/presentation/widgets/cms_date_field.dart';
import 'package:rijiki/features/cms/presentation/widgets/cms_state_card.dart';
import 'package:rijiki/features/event/domain/promo.dart';
import 'package:rijiki/features/event/domain/promo_input.dart';
import 'package:rijiki/shared/widgets/empty_state.dart';
import 'package:rijiki/shared/widgets/error_state.dart';
import 'package:rijiki/shared/widgets/loading_skeleton.dart';

class PromoFormPage extends ConsumerWidget {
  const PromoFormPage({super.key, this.promoId});

  final String? promoId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(cmsPromosProvider);
    final promos = async.value;
    final isEdit = promoId != null;

    Widget body;
    if (promos != null) {
      final promo = isEdit
          ? promos.where((p) => p.id == promoId).firstOrNull
          : null;
      if (isEdit && promo == null) {
        body = Padding(
          padding: const EdgeInsets.all(AppSpacing.lg),
          child: CmsStateCard(
            child: EmptyState(
              icon: Icons.search_off_rounded,
              title: 'Promo tidak ditemukan',
              actionLabel: 'Kembali',
              onAction: () => context.pop(),
            ),
          ),
        );
      } else {
        body = _PromoForm(
          promo: promo,
          takenCodes: {
            for (final p in promos)
              if (p.id != promoId) p.code.trim().toLowerCase(),
          },
        );
      }
    } else if (async.hasError) {
      body = Padding(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: CmsStateCard(
          child: ErrorState(
            message: 'Gagal memuat promo.',
            onRetry: () => ref.invalidate(cmsPromosProvider),
          ),
        ),
      );
    } else {
      body = const Padding(
        padding: EdgeInsets.all(AppSpacing.lg),
        child: LoadingSkeleton(height: 420, radius: AppSpacing.radiusLg),
      );
    }

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(title: Text(isEdit ? 'Ubah promo' : 'Tambah promo')),
      body: body,
    );
  }
}

class _PromoForm extends ConsumerStatefulWidget {
  const _PromoForm({required this.promo, required this.takenCodes});

  final Promo? promo;

  final Set<String> takenCodes;

  @override
  ConsumerState<_PromoForm> createState() => _PromoFormState();
}

class _PromoFormState extends ConsumerState<_PromoForm> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _code;
  late final TextEditingController _title;
  late final TextEditingController _value;
  late final TextEditingController _description;
  late DiscountType _type;
  late bool _active;
  DateTime? _start;
  DateTime? _end;
  bool _submitted = false;

  bool get _isEdit => widget.promo != null;

  @override
  void initState() {
    super.initState();
    final p = widget.promo;
    _code = TextEditingController(text: p?.code ?? '');
    _title = TextEditingController(text: p?.title ?? '');
    _description = TextEditingController(text: p?.description ?? '');
    _type = p?.discountType ?? DiscountType.percentage;
    _active = p?.isActive ?? true;
    _value = TextEditingController(
      text: p == null
          ? ''
          : (p.discountType == DiscountType.percentage
                ? p.discountValue.toString()
                : rupiahInputText(p.discountValue.toDouble())),
    );

    final now = DateTime.now();
    _start = p?.startDate ?? DateTime(now.year, now.month, now.day);
    _end = p?.endDate;
  }

  @override
  void dispose() {
    _code.dispose();
    _title.dispose();
    _value.dispose();
    _description.dispose();
    super.dispose();
  }

  String? get _startError =>
      _submitted && _start == null ? 'Pilih tanggal mulai.' : null;

  String? get _endError {
    final start = _start;
    final end = _end;
    if (end == null) return _submitted ? 'Pilih tanggal selesai.' : null;
    if (start != null && end.isBefore(start)) {
      return 'Tanggal selesai tidak boleh sebelum tanggal mulai.';
    }
    return null;
  }

  Future<DateTime?> _pickDate(DateTime? current) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    return showDatePicker(
      context: context,
      initialDate: current ?? today,
      firstDate: DateTime(today.year - 1),
      lastDate: DateTime(today.year + 3),
    );
  }

  void _selectType(DiscountType type) {
    if (type == _type) return;
    setState(() {
      _type = type;
      _value.clear();
    });
  }

  Future<void> _submit() async {
    final valid = _formKey.currentState?.validate() ?? false;
    setState(() => _submitted = true);
    final start = _start;
    final end = _end;
    if (!valid || start == null || end == null || _endError != null) return;
    FocusScope.of(context).unfocus();

    final messenger = ScaffoldMessenger.of(context);
    final router = GoRouter.of(context);

    final value = _type == DiscountType.percentage
        ? int.parse(_value.text.trim())
        : parseRupiahInput(_value.text).round();

    final input = PromoInput(
      code: _code.text.trim().toUpperCase(),
      title: _title.text.trim(),
      discountType: _type,
      discountValue: value,
      startDate: start,
      endDate: end,
      description: _description.text,
      isActive: _active,
    );

    final ok = await ref
        .read(promoManageProvider.notifier)
        .save(id: widget.promo?.id, input: input);
    if (!mounted) return;

    final message = ok
        ? (_isEdit ? 'Perubahan promo disimpan.' : 'Promo ditambahkan.')
        : (ref.read(promoManageProvider).errorMessage ?? 'Gagal menyimpan.');
    messenger
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(message)));
    if (ok) router.pop();
  }

  @override
  Widget build(BuildContext context) {
    final saving = ref.watch(promoManageProvider).saving;
    final textTheme = Theme.of(context).textTheme;
    final isPercent = _type == DiscountType.percentage;

    final List<TextInputFormatter> valueFormatters = isPercent
        ? [
            FilteringTextInputFormatter.digitsOnly,
            LengthLimitingTextInputFormatter(3),
          ]
        : const [RupiahInputFormatter()];

    return ListView(
      keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.lg,
        AppSpacing.md,
        AppSpacing.lg,
        AppSpacing.xl,
      ),
      children: [
        Container(
          padding: const EdgeInsets.all(AppSpacing.md),
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
            border: Border.all(color: AppColors.outline.withValues(alpha: 0.3)),
          ),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                TextFormField(
                  controller: _code,
                  enabled: !saving,
                  maxLength: 20,
                  textCapitalization: TextCapitalization.characters,
                  inputFormatters: const [
                    _AlphanumericUpperFormatter(),
                  ],
                  decoration: const InputDecoration(
                    labelText: 'Kode promo',
                    counterText: '',
                    helperText: 'Kode yang diketik customer saat order.',
                  ),
                  validator: (value) {
                    final code = (value ?? '').trim();
                    if (code.isEmpty) return 'Isi dulu kode promonya.';
                    if (code.length < 3) return 'Kode minimal 3 karakter.';
                    if (widget.takenCodes.contains(code.toLowerCase())) {
                      return 'Kode ini sudah dipakai.';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: AppSpacing.md),
                TextFormField(
                  controller: _title,
                  enabled: !saving,
                  textCapitalization: TextCapitalization.sentences,
                  maxLength: 60,
                  decoration: const InputDecoration(
                    labelText: 'Judul promo',
                    counterText: '',
                  ),
                  validator: (value) => (value ?? '').trim().isEmpty
                      ? 'Isi dulu judulnya.'
                      : null,
                ),
                const SizedBox(height: AppSpacing.md),
                Text(
                  'Jenis diskon',
                  style: textTheme.labelLarge?.copyWith(
                    color: AppColors.onSurfaceVariant,
                  ),
                ),
                const SizedBox(height: AppSpacing.sm),
                Wrap(
                  spacing: AppSpacing.sm,
                  children: [
                    for (final type in DiscountType.values)
                      ChoiceChip(
                        selected: type == _type,
                        onSelected: saving ? null : (_) => _selectType(type),
                        showCheckmark: false,
                        label: Text(type.cmsLabel),
                        labelStyle: textTheme.labelLarge?.copyWith(
                          color: type == _type
                              ? AppColors.onSurface
                              : AppColors.onSurfaceVariant,
                          fontWeight: type == _type
                              ? FontWeight.w700
                              : FontWeight.w500,
                        ),
                        backgroundColor: AppColors.surface,
                        selectedColor: AppColors.primary.withValues(alpha: 0.3),
                        shape: const StadiumBorder(),
                        side: BorderSide(
                          color: type == _type
                              ? AppColors.primaryDark
                              : AppColors.outline.withValues(alpha: 0.4),
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: AppSpacing.md),
                TextFormField(
                  key: ValueKey(_type),
                  controller: _value,
                  enabled: !saving,
                  keyboardType: TextInputType.number,
                  inputFormatters: valueFormatters,
                  decoration: InputDecoration(
                    labelText: isPercent ? 'Besar diskon' : 'Potongan harga',
                    prefixText: isPercent ? null : 'Rp ',
                    suffixText: isPercent ? '%' : null,
                    helperText: isPercent
                        ? 'Antara 1 sampai 100 persen.'
                        : 'Dipotong langsung dari total order.',
                  ),
                  validator: (value) {
                    final text = (value ?? '').trim();
                    if (isPercent) {
                      final n = int.tryParse(text);
                      if (n == null || n <= 0) return 'Isi persentase diskon.';
                      if (n > 100) return 'Maksimal 100%.';
                      return null;
                    }
                    return parseRupiahInput(text) <= 0
                        ? 'Nominal harus lebih dari 0.'
                        : null;
                  },
                ),
                const SizedBox(height: AppSpacing.md),
                Text(
                  'Masa berlaku',
                  style: textTheme.labelLarge?.copyWith(
                    color: AppColors.onSurfaceVariant,
                  ),
                ),
                const SizedBox(height: AppSpacing.sm),
                CmsDateField(
                  label: 'Tanggal mulai',
                  value: _start,
                  enabled: !saving,
                  errorText: _startError,
                  onPick: () async {
                    final picked = await _pickDate(_start);
                    if (picked != null && mounted) {
                      setState(() => _start = picked);
                    }
                  },
                  onClear: () => setState(() => _start = null),
                ),
                const SizedBox(height: AppSpacing.md),
                CmsDateField(
                  label: 'Tanggal selesai',
                  value: _end,
                  enabled: !saving,
                  errorText: _endError,
                  onPick: () async {
                    final picked = await _pickDate(_end ?? _start);
                    if (picked != null && mounted) {
                      setState(() => _end = picked);
                    }
                  },
                  onClear: () => setState(() => _end = null),
                ),
                const SizedBox(height: AppSpacing.md),
                TextFormField(
                  controller: _description,
                  enabled: !saving,
                  minLines: 2,
                  maxLines: 4,
                  maxLength: 200,
                  textCapitalization: TextCapitalization.sentences,
                  decoration: const InputDecoration(
                    labelText: 'Deskripsi / syarat (opsional)',
                    alignLabelWithHint: true,
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: AppSpacing.md),
        ActiveToggleTile(
          value: _active,
          onChanged: saving ? null : (value) => setState(() => _active = value),
          title: 'Aktif untuk customer',
          subtitle: _active
              ? 'Kode bisa dipakai customer selama masa berlaku.'
              : 'Kode dinonaktifkan, datanya tetap tersimpan.',
        ),
        const SizedBox(height: AppSpacing.lg),
        FilledButton(
          onPressed: saving ? null : _submit,
          child: saving
              ? const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: AppColors.onPrimary,
                  ),
                )
              : Text(_isEdit ? 'Simpan perubahan' : 'Tambah promo'),
        ),
      ],
    );
  }
}

class _AlphanumericUpperFormatter extends TextInputFormatter {
  const _AlphanumericUpperFormatter();

  static final RegExp _invalid = RegExp(r'[^A-Za-z0-9]');

  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    final cleaned = newValue.text.replaceAll(_invalid, '').toUpperCase();
    if (cleaned == newValue.text) return newValue;
    return TextEditingValue(
      text: cleaned,
      selection: TextSelection.collapsed(offset: cleaned.length),
    );
  }
}
