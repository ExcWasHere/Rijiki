import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:rijiki/core/theme/app_colors.dart';
import 'package:rijiki/core/theme/app_spacing.dart';
import 'package:rijiki/core/utils/date_format.dart';
import 'package:rijiki/features/worker_management/domain/worker_input.dart';
import 'package:rijiki/features/worker_management/domain/worker_profile.dart';
import 'package:rijiki/features/worker_management/presentation/controllers/worker_list_controller.dart';
import 'package:rijiki/shared/widgets/empty_state.dart';
import 'package:rijiki/shared/widgets/error_state.dart';
import 'package:rijiki/shared/widgets/loading_skeleton.dart';
import 'package:rijiki/shared/widgets/state_card.dart';

class WorkerFormPage extends ConsumerWidget {
  const WorkerFormPage({super.key, this.workerId});

  final String? workerId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(workersProvider);
    final workers = async.value;
    final isEdit = workerId != null;

    Widget body;
    if (workers != null) {
      final current = isEdit
          ? workers.where((w) => w.profile.id == workerId).firstOrNull
          : null;
      if (isEdit && current == null) {
        body = Padding(
          padding: const EdgeInsets.all(AppSpacing.lg),
          child: StateCard(
            child: EmptyState(
              icon: Icons.search_off_rounded,
              title: 'Worker tidak ditemukan',
              actionLabel: 'Kembali',
              onAction: () => context.pop(),
            ),
          ),
        );
      } else {
        body = _WorkerForm(
          worker: current?.profile,
          others: [
            for (final w in workers)
              if (w.profile.id != workerId) w.profile,
          ],
        );
      }
    } else if (async.hasError) {
      body = Padding(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: StateCard(
          child: ErrorState(
            message: 'Gagal memuat data worker.',
            onRetry: () => ref.invalidate(workersProvider),
          ),
        ),
      );
    } else {
      body = const Padding(
        padding: EdgeInsets.all(AppSpacing.lg),
        child: LoadingSkeleton(height: 460, radius: AppSpacing.radiusLg),
      );
    }

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(title: Text(isEdit ? 'Ubah worker' : 'Tambah worker')),
      body: body,
    );
  }
}

class _WorkerForm extends ConsumerStatefulWidget {
  const _WorkerForm({required this.worker, required this.others});

  final WorkerProfile? worker;
  final List<WorkerProfile> others;

  @override
  ConsumerState<_WorkerForm> createState() => _WorkerFormState();
}

class _WorkerFormState extends ConsumerState<_WorkerForm> {
  static const List<String> _defaultDivisions = [
    'Cleaning',
    'Pickup-Delivery',
    'Reparasi',
  ];

  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _name;
  late final TextEditingController _email;
  late final TextEditingController _phone;
  late final TextEditingController _code;
  late final TextEditingController _division;
  late final TextEditingController _password;
  DateTime? _joinDate;
  bool _showPassword = false;
  bool _dateError = false;

  bool get _isEdit => widget.worker != null;

  @override
  void initState() {
    super.initState();
    final w = widget.worker;
    _name = TextEditingController(text: w?.fullName ?? '');
    _email = TextEditingController(text: w?.email ?? '');
    _phone = TextEditingController(text: w?.phoneNumber ?? '');
    _code = TextEditingController(text: w?.employeeCode ?? '');
    _division = TextEditingController(text: w?.division ?? '');
    _password = TextEditingController();
    _joinDate = w?.joinDate;
  }

  @override
  void dispose() {
    _name.dispose();
    _email.dispose();
    _phone.dispose();
    _code.dispose();
    _division.dispose();
    _password.dispose();
    super.dispose();
  }

  List<String> get _divisionSuggestions => {
    ..._defaultDivisions,
    ...ref.read(workerDivisionsProvider),
  }.toList();

  Future<void> _pickDate() async {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final picked = await showDatePicker(
      context: context,
      initialDate: _joinDate ?? today,
      firstDate: DateTime(today.year - 15),
      lastDate: today,
      helpText: 'Tanggal bergabung',
    );
    if (picked != null && mounted) {
      setState(() {
        _joinDate = picked;
        _dateError = false;
      });
    }
  }

  Future<void> _submit() async {
    final valid = _formKey.currentState?.validate() ?? false;
    if (_joinDate == null) setState(() => _dateError = true);
    if (!valid || _joinDate == null) return;
    FocusScope.of(context).unfocus();

    final messenger = ScaffoldMessenger.of(context);
    final router = GoRouter.of(context);

    final input = WorkerInput(
      fullName: _name.text.trim(),
      email: _email.text.trim(),
      phoneNumber: _phone.text.trim(),
      employeeCode: _code.text.trim().toUpperCase(),
      division: _division.text.trim(),
      joinDate: _joinDate!,
      password: _isEdit ? null : _password.text,
    );

    final ok = await ref
        .read(workerFormProvider.notifier)
        .save(id: widget.worker?.id, input: input);
    if (!mounted) return;

    final message = ok
        ? (_isEdit ? 'Perubahan worker disimpan.' : 'Worker ditambahkan.')
        : (ref.read(workerFormProvider).errorMessage ?? 'Gagal menyimpan.');
    messenger
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(message)));
    if (ok) router.pop();
  }

  @override
  Widget build(BuildContext context) {
    final saving = ref.watch(workerFormProvider).saving;
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
                  decoration: const InputDecoration(labelText: 'Nama lengkap'),
                  validator: (value) => (value ?? '').trim().isEmpty
                      ? 'Isi dulu nama lengkapnya.'
                      : null,
                ),
                const SizedBox(height: AppSpacing.md),
                TextFormField(
                  controller: _email,
                  enabled: !saving && !_isEdit,
                  keyboardType: TextInputType.emailAddress,
                  autocorrect: false,
                  decoration: InputDecoration(
                    labelText: 'Email akun',
                    helperText: _isEdit
                        ? 'Email akun tidak bisa diubah dari sini.'
                        : 'Dipakai worker untuk login.',
                  ),
                  validator: (value) {
                    final email = (value ?? '').trim();
                    if (email.isEmpty) return 'Isi dulu emailnya.';
                    if (!RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$').hasMatch(email)) {
                      return 'Format email belum benar.';
                    }
                    final taken = widget.others.any(
                      (w) => w.email.toLowerCase() == email.toLowerCase(),
                    );
                    return taken ? 'Email ini sudah dipakai worker lain.' : null;
                  },
                ),
                if (!_isEdit) ...[
                  const SizedBox(height: AppSpacing.md),
                  TextFormField(
                    controller: _password,
                    enabled: !saving,
                    obscureText: !_showPassword,
                    autocorrect: false,
                    decoration: InputDecoration(
                      labelText: 'Kata sandi awal',
                      helperText: 'Minimal 8 karakter. Worker bisa menggantinya nanti.',
                      suffixIcon: IconButton(
                        tooltip: _showPassword ? 'Sembunyikan' : 'Tampilkan',
                        icon: Icon(
                          _showPassword
                              ? Icons.visibility_off_outlined
                              : Icons.visibility_outlined,
                        ),
                        onPressed: () =>
                            setState(() => _showPassword = !_showPassword),
                      ),
                    ),
                    validator: (value) => (value ?? '').length < 8
                        ? 'Kata sandi minimal 8 karakter.'
                        : null,
                  ),
                ],
                const SizedBox(height: AppSpacing.md),
                TextFormField(
                  controller: _phone,
                  enabled: !saving,
                  keyboardType: TextInputType.phone,
                  inputFormatters: [
                    FilteringTextInputFormatter.allow(RegExp(r'[0-9+]')),
                    LengthLimitingTextInputFormatter(15),
                  ],
                  decoration: const InputDecoration(
                    labelText: 'Nomor HP',
                    hintText: '08xxxxxxxxxx',
                  ),
                  validator: (value) {
                    final phone = (value ?? '').trim();
                    if (phone.isEmpty) return 'Isi dulu nomor HP-nya.';
                    return RegExp(r'^(\+62|62|0)8\d{7,11}$').hasMatch(phone)
                        ? null
                        : 'Format nomor HP belum benar.';
                  },
                ),
                const SizedBox(height: AppSpacing.md),
                TextFormField(
                  controller: _code,
                  enabled: !saving,
                  textCapitalization: TextCapitalization.characters,
                  decoration: const InputDecoration(
                    labelText: 'Kode pegawai',
                    hintText: 'RJK-W007',
                  ),
                  validator: (value) {
                    final code = (value ?? '').trim().toUpperCase();
                    if (code.isEmpty) return 'Isi dulu kode pegawainya.';
                    final taken = widget.others.any(
                      (w) => w.employeeCode.toUpperCase() == code,
                    );
                    return taken ? 'Kode pegawai ini sudah dipakai.' : null;
                  },
                ),
                const SizedBox(height: AppSpacing.md),
                TextFormField(
                  controller: _division,
                  enabled: !saving,
                  textCapitalization: TextCapitalization.words,
                  decoration: const InputDecoration(labelText: 'Divisi'),
                  validator: (value) => (value ?? '').trim().isEmpty
                      ? 'Isi dulu divisinya.'
                      : null,
                ),
                const SizedBox(height: AppSpacing.sm),
                Wrap(
                  spacing: AppSpacing.sm,
                  runSpacing: AppSpacing.sm,
                  children: [
                    for (final suggestion in _divisionSuggestions)
                      ActionChip(
                        label: Text(suggestion),
                        labelStyle: textTheme.labelMedium,
                        backgroundColor: AppColors.surface,
                        shape: const StadiumBorder(),
                        side: BorderSide(
                          color: AppColors.outline.withValues(alpha: 0.4),
                        ),
                        onPressed: saving
                            ? null
                            : () => setState(() => _division.text = suggestion),
                      ),
                  ],
                ),
                const SizedBox(height: AppSpacing.md),
                InkWell(
                  borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
                  onTap: saving ? null : _pickDate,
                  child: InputDecorator(
                    decoration: InputDecoration(
                      labelText: 'Tanggal bergabung',
                      suffixIcon: const Icon(Icons.calendar_month_rounded),
                      errorText: _dateError ? 'Pilih tanggal bergabung.' : null,
                    ),
                    child: Text(
                      _joinDate == null
                          ? 'Pilih tanggal'
                          : formatDate(_joinDate!),
                      style: textTheme.bodyLarge?.copyWith(
                        color: _joinDate == null
                            ? AppColors.onSurfaceVariant
                            : AppColors.onSurface,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
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
              : Text(_isEdit ? 'Simpan perubahan' : 'Tambah worker'),
        ),
      ],
    );
  }
}
