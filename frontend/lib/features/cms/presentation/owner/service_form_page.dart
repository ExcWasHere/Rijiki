import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:rijiki/core/theme/app_colors.dart';
import 'package:rijiki/core/theme/app_spacing.dart';
import 'package:rijiki/core/utils/rupiah_input_formatter.dart';
import 'package:rijiki/features/cms/presentation/controllers/service_manage_controller.dart';
import 'package:rijiki/features/cms/presentation/utils/service_format.dart';
import 'package:rijiki/features/cms/presentation/widgets/active_toggle_tile.dart';
import 'package:rijiki/features/cms/presentation/widgets/cms_state_card.dart';
import 'package:rijiki/features/service/domain/care_service.dart';
import 'package:rijiki/features/service/domain/care_service_input.dart';
import 'package:rijiki/shared/widgets/empty_state.dart';
import 'package:rijiki/shared/widgets/error_state.dart';
import 'package:rijiki/shared/widgets/loading_skeleton.dart';

class ServiceFormPage extends ConsumerWidget {
  const ServiceFormPage({super.key, this.serviceId});

  final String? serviceId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(cmsServicesProvider);
    final services = async.value;
    final isEdit = serviceId != null;

    Widget body;
    if (services != null) {
      final service = isEdit
          ? services.where((s) => s.id == serviceId).firstOrNull
          : null;
      if (isEdit && service == null) {
        body = Padding(
          padding: const EdgeInsets.all(AppSpacing.lg),
          child: CmsStateCard(
            child: EmptyState(
              icon: Icons.search_off_rounded,
              title: 'Layanan tidak ditemukan',
              actionLabel: 'Kembali',
              onAction: () => context.pop(),
            ),
          ),
        );
      } else {
        body = _ServiceForm(
          service: service,
          takenNames: {
            for (final s in services)
              if (s.id != serviceId) s.name.trim().toLowerCase(),
          },
        );
      }
    } else if (async.hasError) {
      body = Padding(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: CmsStateCard(
          child: ErrorState(
            message: 'Gagal memuat layanan.',
            onRetry: () => ref.invalidate(cmsServicesProvider),
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
      appBar: AppBar(title: Text(isEdit ? 'Ubah layanan' : 'Tambah layanan')),
      body: body,
    );
  }
}

class _ServiceForm extends ConsumerStatefulWidget {
  const _ServiceForm({required this.service, required this.takenNames});

  final CareService? service;

  final Set<String> takenNames;

  @override
  ConsumerState<_ServiceForm> createState() => _ServiceFormState();
}

class _ServiceFormState extends ConsumerState<_ServiceForm> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _name;
  late final TextEditingController _price;
  late final TextEditingController _duration;
  late final TextEditingController _description;
  late ServiceCategory _category;
  late DurationUnit _unit;
  late bool _active;

  bool get _isEdit => widget.service != null;

  @override
  void initState() {
    super.initState();
    final s = widget.service;
    _name = TextEditingController(text: s?.name ?? '');
    _price = TextEditingController(
      text: s == null ? '' : rupiahInputText(s.basePrice.toDouble()),
    );
    _description = TextEditingController(text: s?.description ?? '');
    _category = s?.category ?? ServiceCategory.cuciSepatu;
    _active = s?.isActive ?? true;

    final minutes = s?.estimatedDurationMinutes;
    if (minutes == null) {
      _unit = DurationUnit.hour;
      _duration = TextEditingController();
    } else {
      final split = splitDuration(minutes);
      _unit = split.unit;
      _duration = TextEditingController(text: split.value.toString());
    }
  }

  @override
  void dispose() {
    _name.dispose();
    _price.dispose();
    _duration.dispose();
    _description.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    FocusScope.of(context).unfocus();

    final messenger = ScaffoldMessenger.of(context);
    final router = GoRouter.of(context);
    final durationText = _duration.text.trim();

    final input = CareServiceInput(
      name: _name.text.trim(),
      category: _category,
      basePrice: parseRupiahInput(_price.text).round(),
      description: _description.text,
      estimatedDurationMinutes: durationText.isEmpty
          ? null
          : int.parse(durationText) * _unit.minutes,
      isActive: _active,
    );

    final ok = await ref
        .read(serviceManageProvider.notifier)
        .save(id: widget.service?.id, input: input);
    if (!mounted) return;

    final message = ok
        ? (_isEdit ? 'Perubahan layanan disimpan.' : 'Layanan ditambahkan.')
        : (ref.read(serviceManageProvider).errorMessage ?? 'Gagal menyimpan.');
    messenger
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(message)));
    if (ok) router.pop();
  }

  @override
  Widget build(BuildContext context) {
    final saving = ref.watch(serviceManageProvider).saving;
    final textTheme = Theme.of(context).textTheme;

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
                  controller: _name,
                  enabled: !saving,
                  textCapitalization: TextCapitalization.words,
                  maxLength: 60,
                  decoration: const InputDecoration(
                    labelText: 'Nama layanan',
                    counterText: '',
                  ),
                  validator: (value) {
                    final name = (value ?? '').trim();
                    if (name.isEmpty) return 'Isi dulu nama layanannya.';
                    if (widget.takenNames.contains(name.toLowerCase())) {
                      return 'Nama layanan ini sudah dipakai.';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: AppSpacing.md),
                Text(
                  'Kategori',
                  style: textTheme.labelLarge?.copyWith(
                    color: AppColors.onSurfaceVariant,
                  ),
                ),
                const SizedBox(height: AppSpacing.sm),
                Wrap(
                  spacing: AppSpacing.sm,
                  children: [
                    for (final category in ServiceCategory.values)
                      ChoiceChip(
                        selected: category == _category,
                        onSelected: saving
                            ? null
                            : (_) => setState(() => _category = category),
                        showCheckmark: false,
                        label: Text(category.label),
                        labelStyle: textTheme.labelLarge?.copyWith(
                          color: category == _category
                              ? AppColors.onSurface
                              : AppColors.onSurfaceVariant,
                          fontWeight: category == _category
                              ? FontWeight.w700
                              : FontWeight.w500,
                        ),
                        backgroundColor: AppColors.surface,
                        selectedColor: AppColors.primary.withValues(alpha: 0.3),
                        shape: const StadiumBorder(),
                        side: BorderSide(
                          color: category == _category
                              ? AppColors.primaryDark
                              : AppColors.outline.withValues(alpha: 0.4),
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: AppSpacing.md),
                TextFormField(
                  controller: _price,
                  enabled: !saving,
                  keyboardType: TextInputType.number,
                  inputFormatters: const [RupiahInputFormatter()],
                  decoration: InputDecoration(
                    labelText: 'Harga dasar',
                    prefixText: 'Rp ',
                    helperText: _isEdit
                        ? 'Perubahan harga berlaku untuk pemesanan baru; pemesanan '
                              'yang sudah dibuat memakai harga saat dipesan.'
                        : null,
                    helperMaxLines: 3,
                  ),
                  validator: (value) => parseRupiahInput(value ?? '') <= 0
                      ? 'Harga harus lebih dari 0.'
                      : null,
                ),
                const SizedBox(height: AppSpacing.md),
                Text(
                  'Estimasi pengerjaan (opsional)',
                  style: textTheme.labelLarge?.copyWith(
                    color: AppColors.onSurfaceVariant,
                  ),
                ),
                const SizedBox(height: AppSpacing.sm),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    SizedBox(
                      width: 96,
                      child: TextFormField(
                        controller: _duration,
                        enabled: !saving,
                        keyboardType: TextInputType.number,
                        inputFormatters: [
                          FilteringTextInputFormatter.digitsOnly,
                          LengthLimitingTextInputFormatter(4),
                        ],
                        decoration: const InputDecoration(hintText: 'Lama'),
                        validator: (value) {
                          final text = (value ?? '').trim();
                          if (text.isEmpty) return null;
                          return int.parse(text) <= 0
                              ? 'Harus lebih dari 0.'
                              : null;
                        },
                      ),
                    ),
                    const SizedBox(width: AppSpacing.sm + 4),
                    Expanded(
                      child: SegmentedButton<DurationUnit>(
                        showSelectedIcon: false,
                        segments: [
                          for (final unit in DurationUnit.values)
                            ButtonSegment(value: unit, label: Text(unit.label)),
                        ],
                        selected: {_unit},
                        onSelectionChanged: saving
                            ? null
                            : (selection) =>
                                  setState(() => _unit = selection.first),
                      ),
                    ),
                  ],
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
                    labelText: 'Deskripsi (opsional)',
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
          title: 'Tampil di aplikasi customer',
          subtitle: _active
              ? 'Customer bisa memilih layanan ini saat order.'
              : 'Layanan disembunyikan dari customer, datanya tetap tersimpan.',
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
              : Text(_isEdit ? 'Simpan perubahan' : 'Tambah layanan'),
        ),
      ],
    );
  }
}
