import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:rijiki/core/theme/app_colors.dart';
import 'package:rijiki/core/theme/app_spacing.dart';
import 'package:rijiki/core/utils/rupiah_input_formatter.dart';
import 'package:rijiki/features/cms/presentation/controllers/merchandise_manage_controller.dart';
import 'package:rijiki/features/cms/presentation/widgets/active_toggle_tile.dart';
import 'package:rijiki/features/cms/presentation/widgets/cms_state_card.dart';
import 'package:rijiki/features/merchandise/domain/merchandise.dart';
import 'package:rijiki/features/merchandise/domain/merchandise_input.dart';
import 'package:rijiki/shared/widgets/empty_state.dart';
import 'package:rijiki/shared/widgets/error_state.dart';
import 'package:rijiki/shared/widgets/image_picker_field.dart';
import 'package:rijiki/shared/widgets/loading_skeleton.dart';

class MerchandiseFormPage extends ConsumerWidget {
  const MerchandiseFormPage({super.key, this.merchandiseId});

  final String? merchandiseId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(cmsMerchandiseProvider);
    final items = async.value;
    final isEdit = merchandiseId != null;

    Widget body;
    if (items != null) {
      final item = isEdit
          ? items.where((m) => m.id == merchandiseId).firstOrNull
          : null;
      if (isEdit && item == null) {
        body = Padding(
          padding: const EdgeInsets.all(AppSpacing.lg),
          child: CmsStateCard(
            child: EmptyState(
              icon: Icons.search_off_rounded,
              title: 'Merchandise tidak ditemukan',
              actionLabel: 'Kembali',
              onAction: () => context.pop(),
            ),
          ),
        );
      } else {
        body = _MerchandiseForm(item: item);
      }
    } else if (async.hasError) {
      body = Padding(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: CmsStateCard(
          child: ErrorState(
            message: 'Gagal memuat merchandise.',
            onRetry: () => ref.invalidate(cmsMerchandiseProvider),
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
      appBar: AppBar(
        title: Text(isEdit ? 'Ubah merchandise' : 'Tambah merchandise'),
      ),
      body: body,
    );
  }
}

class _MerchandiseForm extends ConsumerStatefulWidget {
  const _MerchandiseForm({required this.item});

  final Merchandise? item;

  @override
  ConsumerState<_MerchandiseForm> createState() => _MerchandiseFormState();
}

class _MerchandiseFormState extends ConsumerState<_MerchandiseForm> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _name;
  late final TextEditingController _price;
  late final TextEditingController _points;
  late final TextEditingController _stock;
  late final TextEditingController _description;
  late bool _active;
  String? _image;

  bool get _isEdit => widget.item != null;

  @override
  void initState() {
    super.initState();
    final m = widget.item;
    _name = TextEditingController(text: m?.name ?? '');
    _price = TextEditingController(
      text: m == null ? '' : rupiahInputText(m.price.toDouble()),
    );
    _points = TextEditingController(text: m?.pointsCost?.toString() ?? '');
    _stock = TextEditingController(text: m?.stockQuantity?.toString() ?? '');
    _description = TextEditingController(text: m?.description ?? '');
    _active = m?.isActive ?? true;
    _image = m?.imageUrl;
  }

  @override
  void dispose() {
    _name.dispose();
    _price.dispose();
    _points.dispose();
    _stock.dispose();
    _description.dispose();
    super.dispose();
  }

  int? _intOrNull(TextEditingController controller) {
    final text = controller.text.trim();
    return text.isEmpty ? null : int.parse(text);
  }

  Future<void> _submit() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    FocusScope.of(context).unfocus();

    final messenger = ScaffoldMessenger.of(context);
    final router = GoRouter.of(context);

    final input = MerchandiseInput(
      name: _name.text.trim(),
      price: parseRupiahInput(_price.text).round(),
      pointsCost: _intOrNull(_points),
      stockQuantity: _intOrNull(_stock),
      description: _description.text,
      imageUrl: _image,
      isActive: _active,
    );

    final ok = await ref
        .read(merchandiseManageProvider.notifier)
        .save(id: widget.item?.id, input: input);
    if (!mounted) return;

    final message = ok
        ? (_isEdit ? 'Perubahan merchandise disimpan.' : 'Merchandise ditambahkan.')
        : (ref.read(merchandiseManageProvider).errorMessage ??
              'Gagal menyimpan.');
    messenger
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(message)));
    if (ok) router.pop();
  }

  @override
  Widget build(BuildContext context) {
    final saving = ref.watch(merchandiseManageProvider).saving;
    final textTheme = Theme.of(context).textTheme;
    final digitsOnly = <TextInputFormatter>[
      FilteringTextInputFormatter.digitsOnly,
      LengthLimitingTextInputFormatter(7),
    ];

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
                    labelText: 'Nama merchandise',
                    counterText: '',
                  ),
                  validator: (value) => (value ?? '').trim().isEmpty
                      ? 'Isi dulu nama merchandise.'
                      : null,
                ),
                const SizedBox(height: AppSpacing.md),
                TextFormField(
                  controller: _price,
                  enabled: !saving,
                  keyboardType: TextInputType.number,
                  inputFormatters: const [RupiahInputFormatter()],
                  decoration: const InputDecoration(
                    labelText: 'Harga referensi',
                    prefixText: 'Rp ',
                    helperText:
                        'Hanya informasi; merchandise tidak dijual lewat pemesanan.',
                    helperMaxLines: 2,
                  ),
                  validator: (value) => parseRupiahInput(value ?? '') <= 0
                      ? 'Harga harus lebih dari 0.'
                      : null,
                ),
                const SizedBox(height: AppSpacing.md),
                TextFormField(
                  controller: _points,
                  enabled: !saving,
                  keyboardType: TextInputType.number,
                  inputFormatters: digitsOnly,
                  decoration: const InputDecoration(
                    labelText: 'Poin penukaran (opsional)',
                    suffixText: 'poin',
                    helperText: 'Kosongkan bila belum bisa ditukar.',
                  ),
                  validator: (value) {
                    final text = (value ?? '').trim();
                    if (text.isEmpty) return null;
                    return int.parse(text) <= 0
                        ? 'Poin harus lebih dari 0.'
                        : null;
                  },
                ),
                const SizedBox(height: AppSpacing.md),
                TextFormField(
                  controller: _stock,
                  enabled: !saving,
                  keyboardType: TextInputType.number,
                  inputFormatters: digitsOnly,
                  decoration: const InputDecoration(
                    labelText: 'Stok (opsional)',
                    suffixText: 'pcs',
                    helperText: 'Kosongkan bila stok tidak dikelola. Isi 0 bila habis.',
                    helperMaxLines: 2,
                  ),
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
                const SizedBox(height: AppSpacing.sm),
                Text(
                  'Foto produk (opsional)',
                  style: textTheme.labelLarge?.copyWith(
                    color: AppColors.onSurfaceVariant,
                  ),
                ),
                const SizedBox(height: AppSpacing.sm),
                ImagePickerField(
                  path: _image,
                  onChanged: (path) => setState(() => _image = path),
                  label: 'Pilih foto',
                  attachedLabel: 'Foto terpilih',
                  enabled: !saving,
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: AppSpacing.md),
        ActiveToggleTile(
          value: _active,
          onChanged: saving ? null : (value) => setState(() => _active = value),
          title: 'Tampil di katalog customer',
          subtitle: _active
              ? 'Customer bisa melihat merchandise ini.'
              : 'Disembunyikan dari katalog, datanya tetap tersimpan.',
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
              : Text(_isEdit ? 'Simpan perubahan' : 'Tambah merchandise'),
        ),
      ],
    );
  }
}
