import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:rijiki/core/enums/event_type.dart';
import 'package:rijiki/core/theme/app_colors.dart';
import 'package:rijiki/core/theme/app_spacing.dart';
import 'package:rijiki/features/cms/presentation/controllers/event_manage_controller.dart';
import 'package:rijiki/features/cms/presentation/utils/event_format.dart';
import 'package:rijiki/features/cms/presentation/widgets/active_toggle_tile.dart';
import 'package:rijiki/features/cms/presentation/widgets/cms_date_field.dart';
import 'package:rijiki/features/cms/presentation/widgets/cms_state_card.dart';
import 'package:rijiki/features/event/domain/promo_event.dart';
import 'package:rijiki/features/event/domain/promo_event_input.dart';
import 'package:rijiki/shared/widgets/empty_state.dart';
import 'package:rijiki/shared/widgets/error_state.dart';
import 'package:rijiki/shared/widgets/image_picker_field.dart';
import 'package:rijiki/shared/widgets/loading_skeleton.dart';

class EventFormPage extends ConsumerWidget {
  const EventFormPage({super.key, this.eventId});

  final String? eventId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(cmsEventsProvider);
    final events = async.value;
    final isEdit = eventId != null;

    Widget body;
    if (events != null) {
      final event = isEdit
          ? events.where((e) => e.id == eventId).firstOrNull
          : null;
      if (isEdit && event == null) {
        body = Padding(
          padding: const EdgeInsets.all(AppSpacing.lg),
          child: CmsStateCard(
            child: EmptyState(
              icon: Icons.search_off_rounded,
              title: 'Event tidak ditemukan',
              actionLabel: 'Kembali',
              onAction: () => context.pop(),
            ),
          ),
        );
      } else {
        body = _EventForm(event: event);
      }
    } else if (async.hasError) {
      body = Padding(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: CmsStateCard(
          child: ErrorState(
            message: 'Gagal memuat event.',
            onRetry: () => ref.invalidate(cmsEventsProvider),
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
      appBar: AppBar(title: Text(isEdit ? 'Ubah event' : 'Tambah event')),
      body: body,
    );
  }
}

class _EventForm extends ConsumerStatefulWidget {
  const _EventForm({required this.event});

  final PromoEvent? event;

  @override
  ConsumerState<_EventForm> createState() => _EventFormState();
}

class _EventFormState extends ConsumerState<_EventForm> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _title;
  late final TextEditingController _description;
  late EventType _type;
  late bool _published;
  DateTime? _start;
  DateTime? _end;
  String? _banner;

  bool get _isEdit => widget.event != null;

  @override
  void initState() {
    super.initState();
    final e = widget.event;
    _title = TextEditingController(text: e?.title ?? '');
    _description = TextEditingController(text: e?.description ?? '');
    _type = e?.type ?? EventType.promo;
    _published = e?.isPublished ?? true;
    _start = e?.startDate;
    _end = e?.endDate;
    _banner = e?.bannerImageUrl;
  }

  @override
  void dispose() {
    _title.dispose();
    _description.dispose();
    super.dispose();
  }

  String? get _endError {
    final start = _start;
    final end = _end;
    if (start != null && end != null && end.isBefore(start)) {
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

  Future<void> _submit() async {
    final valid = _formKey.currentState?.validate() ?? false;
    if (!valid || _endError != null) {
      setState(() {});
      return;
    }
    FocusScope.of(context).unfocus();

    final messenger = ScaffoldMessenger.of(context);
    final router = GoRouter.of(context);

    final input = PromoEventInput(
      title: _title.text.trim(),
      type: _type,
      description: _description.text,
      bannerImageUrl: _banner,
      startDate: _start,
      endDate: _end,
      isPublished: _published,
    );

    final ok = await ref
        .read(eventManageProvider.notifier)
        .save(id: widget.event?.id, input: input);
    if (!mounted) return;

    final message = ok
        ? (_isEdit ? 'Perubahan event disimpan.' : 'Event ditambahkan.')
        : (ref.read(eventManageProvider).errorMessage ?? 'Gagal menyimpan.');
    messenger
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(message)));
    if (ok) router.pop();
  }

  @override
  Widget build(BuildContext context) {
    final saving = ref.watch(eventManageProvider).saving;
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
                  controller: _title,
                  enabled: !saving,
                  textCapitalization: TextCapitalization.sentences,
                  maxLength: 80,
                  decoration: const InputDecoration(
                    labelText: 'Judul',
                    counterText: '',
                  ),
                  validator: (value) => (value ?? '').trim().isEmpty
                      ? 'Isi dulu judulnya.'
                      : null,
                ),
                const SizedBox(height: AppSpacing.md),
                Text(
                  'Jenis',
                  style: textTheme.labelLarge?.copyWith(
                    color: AppColors.onSurfaceVariant,
                  ),
                ),
                const SizedBox(height: AppSpacing.sm),
                Wrap(
                  spacing: AppSpacing.sm,
                  runSpacing: AppSpacing.sm,
                  children: [
                    for (final type in EventType.values)
                      ChoiceChip(
                        selected: type == _type,
                        onSelected: saving
                            ? null
                            : (_) => setState(() => _type = type),
                        showCheckmark: false,
                        avatar: Icon(type.cmsIcon, size: 16, color: type.cmsColor),
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
                        selectedColor: type.cmsColor.withValues(alpha: 0.16),
                        shape: const StadiumBorder(),
                        side: BorderSide(
                          color: type == _type
                              ? type.cmsColor
                              : AppColors.outline.withValues(alpha: 0.4),
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: AppSpacing.md),
                TextFormField(
                  controller: _description,
                  enabled: !saving,
                  minLines: 2,
                  maxLines: 5,
                  maxLength: 300,
                  textCapitalization: TextCapitalization.sentences,
                  decoration: const InputDecoration(
                    labelText: 'Deskripsi (opsional)',
                    alignLabelWithHint: true,
                  ),
                ),
                const SizedBox(height: AppSpacing.sm),
                Text(
                  'Masa tayang (opsional)',
                  style: textTheme.labelLarge?.copyWith(
                    color: AppColors.onSurfaceVariant,
                  ),
                ),
                const SizedBox(height: AppSpacing.sm),
                CmsDateField(
                  label: 'Tanggal mulai',
                  value: _start,
                  enabled: !saving,
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
                Text(
                  'Banner (opsional)',
                  style: textTheme.labelLarge?.copyWith(
                    color: AppColors.onSurfaceVariant,
                  ),
                ),
                const SizedBox(height: AppSpacing.sm),
                ImagePickerField(
                  path: _banner,
                  onChanged: (path) => setState(() => _banner = path),
                  label: 'Pilih banner',
                  attachedLabel: 'Banner terpilih',
                  enabled: !saving,
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: AppSpacing.md),
        ActiveToggleTile(
          value: _published,
          onChanged: saving ? null : (value) => setState(() => _published = value),
          title: 'Tampil di aplikasi customer',
          subtitle: _published
              ? 'Event tayang di halaman Acara & Promo.'
              : 'Event disembunyikan dari customer, datanya tetap tersimpan.',
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
              : Text(_isEdit ? 'Simpan perubahan' : 'Tambah event'),
        ),
      ],
    );
  }
}
