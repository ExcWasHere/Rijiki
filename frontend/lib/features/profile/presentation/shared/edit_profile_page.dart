import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:rijiki/core/constants/app_strings.dart';
import 'package:rijiki/core/enums/user_role.dart';
import 'package:rijiki/core/error/failure.dart';
import 'package:rijiki/core/location/location_service.dart';
import 'package:rijiki/core/location/service_area.dart';
import 'package:rijiki/core/session/app_user.dart';
import 'package:rijiki/core/session/session_provider.dart';
import 'package:rijiki/core/theme/app_colors.dart';
import 'package:rijiki/core/theme/app_spacing.dart';
import 'package:rijiki/features/onboarding/presentation/controllers/onboarding_controller.dart'
    show LocateResult, LocationSource;
import 'package:rijiki/features/onboarding/presentation/pages/location_picker_page.dart';
import 'package:rijiki/features/profile/presentation/controller/edit_profile_controller.dart';
import 'package:rijiki/shared/widgets/app_button.dart';
import 'package:rijiki/shared/widgets/app_text_field.dart';
import 'package:rijiki/shared/widgets/image_source_sheet.dart';

/// Halaman "Data pribadi" / "Edit profil" yang dipakai semua role.
/// Customer: nama, HP, alamat + titik. Owner/worker: nama dan HP.
/// Semua role: foto profil. Email hanya tampil (read-only).
class EditProfilePage extends ConsumerStatefulWidget {
  const EditProfilePage({super.key});

  @override
  ConsumerState<EditProfilePage> createState() => _EditProfilePageState();
}

class _EditProfilePageState extends ConsumerState<EditProfilePage> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _name;
  late final TextEditingController _phone;
  late final TextEditingController _email;
  late final TextEditingController _address;

  @override
  void initState() {
    super.initState();
    final initial = ref.read(editProfileControllerProvider);
    final user = ref.read(sessionProvider);
    final notifier = ref.read(editProfileControllerProvider.notifier);

    _name = TextEditingController(text: initial.name)
      ..addListener(() => notifier.updateName(_name.text));
    _phone = TextEditingController(text: initial.phone)
      ..addListener(() => notifier.updatePhone(_phone.text));
    _address = TextEditingController(text: initial.address);
    _email = TextEditingController(text: user?.email ?? '');
  }

  @override
  void dispose() {
    _name.dispose();
    _phone.dispose();
    _email.dispose();
    _address.dispose();
    super.dispose();
  }

  void _toast(String message, {String? actionLabel, VoidCallback? onAction}) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text(message),
          action: actionLabel == null
              ? null
              : SnackBarAction(label: actionLabel, onPressed: onAction ?? () {}),
        ),
      );
  }

  Future<void> _pickAvatar() async {
    final path = await pickImageFromSheet(context, maxSize: 512, quality: 85);
    if (path == null || !mounted) return;
    ref.read(editProfileControllerProvider.notifier).setAvatar(path);
  }

  void _report(LocateResult result) {
    final location = ref.read(locationServiceProvider);
    switch (result) {
      case LocateResult.success:
        return;
      case LocateResult.addressNotFound:
        _toast(
          'Titik lokasimu tersimpan, tapi alamatnya tidak terbaca. '
          'Ketik alamat lengkapmu ya.',
        );
      case LocateResult.serviceDisabled:
        _toast(
          'GPS belum menyala.',
          actionLabel: 'Nyalakan',
          onAction: location.openLocationSettings,
        );
      case LocateResult.denied:
        _toast(
          'Izin lokasi ditolak. Kamu bisa mengetik alamat atau memilih di peta.',
        );
      case LocateResult.deniedForever:
        _toast(
          'Izin lokasi diblokir. Aktifkan lewat pengaturan aplikasi.',
          actionLabel: 'Pengaturan',
          onAction: location.openAppSettings,
        );
      case LocateResult.unavailable:
        _toast('Lokasi belum bisa dibaca. Coba lagi atau pilih di peta.');
      case LocateResult.outOfArea:
        _toast(
          'Lokasimu saat ini di luar area layanan Rijiki. '
          'Kamu bisa mengetik alamat atau memilih di peta.',
        );
    }
  }

  Future<void> _useMyLocation() async {
    final result = await ref
        .read(editProfileControllerProvider.notifier)
        .useCurrentLocation();
    if (!mounted) return;
    _report(result);
  }

  Future<void> _pickOnMap() async {
    final state = ref.read(editProfileControllerProvider);
    final picked = await Navigator.of(context).push<PickedLocation>(
      MaterialPageRoute(
        builder: (_) => LocationPickerPage(initialPoint: state.point),
      ),
    );
    if (picked == null || !mounted) return;

    ref
        .read(editProfileControllerProvider.notifier)
        .applyPickedLocation(picked.point, picked.address);

    final hasAddress = ref
        .read(editProfileControllerProvider)
        .address
        .trim()
        .isNotEmpty;
    if (picked.address == null && !hasAddress) {
      _toast('Alamat titik ini tidak terbaca. Ketik alamat lengkapmu ya.');
    }
  }

  Future<void> _save(AppUser user) async {
    FocusScope.of(context).unfocus();

    final state = ref.read(editProfileControllerProvider);
    if (!state.hasChanges(user)) {
      _toast('Belum ada perubahan.');
      return;
    }
    if (!(_formKey.currentState?.validate() ?? false)) return;

    try {
      await ref.read(editProfileControllerProvider.notifier).save();
      if (!mounted) return;
      _toast('Data pribadi berhasil disimpan.');
      context.pop();
    } on Failure catch (e) {
      if (!mounted) return;
      _toast(e.message);
    } catch (_) {
      if (!mounted) return;
      _toast(AppStrings.errUnknown);
    }
  }

  Future<bool> _confirmDiscard() async {
    final discard = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Buang perubahan?'),
        content: const Text('Perubahan yang belum disimpan akan hilang.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('Lanjut edit'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            child: const Text('Buang'),
          ),
        ],
      ),
    );
    return discard ?? false;
  }

  @override
  Widget build(BuildContext context) {
    final user = ref.watch(sessionProvider);
    final state = ref.watch(editProfileControllerProvider);
    final controller = ref.read(editProfileControllerProvider.notifier);

    ref.listen<String>(
      editProfileControllerProvider.select((s) => s.address),
      (_, next) {
        if (_address.text != next) {
          _address.value = TextEditingValue(
            text: next,
            selection: TextSelection.collapsed(offset: next.length),
          );
        }
      },
    );

    if (user == null) return const Scaffold(body: SizedBox.shrink());

    final isCustomer = user.role == UserRole.customer;
    final dirty = state.hasChanges(user);
    final textTheme = Theme.of(context).textTheme;

    return PopScope(
      canPop: !dirty && !state.isSubmitting,
      onPopInvokedWithResult: (didPop, _) async {
        if (didPop || state.isSubmitting) return;
        final discard = await _confirmDiscard();
        if (discard && context.mounted) context.pop();
      },
      child: Scaffold(
        backgroundColor: AppColors.background,
        appBar: AppBar(title: const Text('Data pribadi')),
        body: SafeArea(
          child: GestureDetector(
            behavior: HitTestBehavior.translucent,
            onTap: () => FocusScope.of(context).unfocus(),
            child: Form(
              key: _formKey,
              child: ListView(
                keyboardDismissBehavior:
                    ScrollViewKeyboardDismissBehavior.onDrag,
                padding: const EdgeInsets.all(AppSpacing.md),
                children: [
                  Center(
                    child: _AvatarPicker(
                      avatarPath: state.avatarPath,
                      avatarUrl: user.avatarUrl,
                      name: state.name,
                      enabled: !state.isSubmitting,
                      onTap: _pickAvatar,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.lg),
                  AppTextField(
                    controller: _name,
                    label: 'Nama lengkap',
                    prefixIcon: Icons.person_outline_rounded,
                    keyboardType: TextInputType.name,
                    textInputAction: TextInputAction.next,
                    autofillHints: const [AutofillHints.name],
                    enabled: !state.isSubmitting,
                    validator: EditProfileController.validateName,
                  ),
                  const SizedBox(height: AppSpacing.md),
                  AppTextField(
                    controller: _phone,
                    label: 'Nomor HP',
                    hint: 'Contoh: 8123456789',
                    prefixIcon: Icons.phone_outlined,
                    keyboardType: TextInputType.phone,
                    textInputAction: isCustomer
                        ? TextInputAction.next
                        : TextInputAction.done,
                    autofillHints: const [AutofillHints.telephoneNumber],
                    enabled: !state.isSubmitting,
                    validator: EditProfileController.validatePhone,
                  ),
                  const SizedBox(height: AppSpacing.md),
                  AppTextField(
                    controller: _email,
                    label: AppStrings.emailLabel,
                    prefixIcon: Icons.mail_outline_rounded,
                    enabled: false,
                  ),
                  Padding(
                    padding: const EdgeInsets.only(
                      left: AppSpacing.sm,
                      top: AppSpacing.xs,
                    ),
                    child: Text(
                      'Email tidak bisa diubah.',
                      style: textTheme.bodySmall?.copyWith(
                        color: AppColors.onSurfaceVariant,
                      ),
                    ),
                  ),
                  if (isCustomer) ...[
                    const SizedBox(height: AppSpacing.lg),
                    Text(
                      'Alamat utama',
                      style: textTheme.titleSmall?.copyWith(
                        color: AppColors.onSurfaceVariant,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: AppSpacing.sm),
                    TextFormField(
                      controller: _address,
                      enabled: !state.isSubmitting,
                      onChanged: controller.updateAddress,
                      validator: EditProfileController.validateAddress,
                      minLines: 2,
                      maxLines: 4,
                      keyboardType: TextInputType.streetAddress,
                      textCapitalization: TextCapitalization.words,
                      decoration: const InputDecoration(
                        labelText: 'Alamat lengkap',
                        hintText: 'Cari nama jalan, gedung, atau perumahan...',
                        prefixIcon: Icon(Icons.location_on_outlined),
                      ),
                    ),
                    const SizedBox(height: AppSpacing.sm),
                    _PointStatus(state: state),
                    const SizedBox(height: AppSpacing.sm),
                    Row(
                      children: [
                        Expanded(
                          child: _LocationButton(
                            icon: Icons.my_location_rounded,
                            label: 'Lokasi saya',
                            loading: state.isLocating,
                            onPressed: state.isLocating || state.isSubmitting
                                ? null
                                : _useMyLocation,
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: _LocationButton(
                            icon: Icons.map_outlined,
                            label: 'Pilih di peta',
                            onPressed: state.isSubmitting ? null : _pickOnMap,
                          ),
                        ),
                      ],
                    ),
                  ],
                  const SizedBox(height: AppSpacing.xl),
                  AppButton(
                    label: 'Simpan',
                    isLoading: state.isSubmitting,
                    onPressed: () => _save(user),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _AvatarPicker extends StatelessWidget {
  const _AvatarPicker({
    required this.avatarPath,
    required this.avatarUrl,
    required this.name,
    required this.enabled,
    required this.onTap,
  });

  static const double _size = 104;

  final String? avatarPath;
  final String? avatarUrl;
  final String name;
  final bool enabled;
  final VoidCallback onTap;

  String get _initials {
    final words = name
        .trim()
        .split(RegExp(r'\s+'))
        .where((word) => word.isNotEmpty)
        .toList();
    if (words.isEmpty) return '?';
    if (words.length == 1) return words.first[0].toUpperCase();
    return '${words.first[0]}${words.last[0]}'.toUpperCase();
  }

  Widget _initialsBox(BuildContext context) {
    return ColoredBox(
      color: AppColors.primary,
      child: Center(
        child: Text(
          _initials,
          style: Theme.of(context).textTheme.headlineMedium?.copyWith(
            color: AppColors.onPrimary,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
    );
  }

  Widget _image(BuildContext context) {
    final fallback = _initialsBox(context);
    Widget errorBuilder(BuildContext _, Object _, StackTrace? _) => fallback;

    final local = avatarPath;
    if (local != null) {
      return Image.file(
        File(local),
        fit: BoxFit.cover,
        errorBuilder: errorBuilder,
      );
    }

    final remote = avatarUrl;
    if (remote == null || remote.isEmpty) return fallback;
    if (remote.startsWith('http')) {
      return Image.network(
        remote,
        fit: BoxFit.cover,
        errorBuilder: errorBuilder,
      );
    }
    return Image.file(File(remote), fit: BoxFit.cover, errorBuilder: errorBuilder);
  }

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: 'Ganti foto profil',
      child: GestureDetector(
        onTap: enabled ? onTap : null,
        child: SizedBox(
          width: _size,
          height: _size,
          child: Stack(
            clipBehavior: Clip.none,
            children: [
              Positioned.fill(
                child: ClipOval(child: _image(context)),
              ),
              Positioned(
                right: -2,
                bottom: -2,
                child: Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: AppColors.rijikiBlue,
                    shape: BoxShape.circle,
                    border: Border.all(color: AppColors.surface, width: 2),
                  ),
                  child: const Icon(
                    Icons.photo_camera_rounded,
                    size: 16,
                    color: Colors.white,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _LocationButton extends StatelessWidget {
  const _LocationButton({
    required this.icon,
    required this.label,
    required this.onPressed,
    this.loading = false,
  });

  final IconData icon;
  final String label;
  final VoidCallback? onPressed;
  final bool loading;

  @override
  Widget build(BuildContext context) {
    return OutlinedButton.icon(
      onPressed: onPressed,
      style: OutlinedButton.styleFrom(
        foregroundColor: AppColors.rijikiBlue,
        backgroundColor: Colors.white,
        minimumSize: const Size.fromHeight(46),
        shape: const StadiumBorder(),
        side: const BorderSide(color: AppColors.rijikiBlue),
        textStyle: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
      ),
      icon: loading
          ? const SizedBox(
              width: 16,
              height: 16,
              child: CircularProgressIndicator(strokeWidth: 2),
            )
          : Icon(icon, size: 18),
      label: Text(label),
    );
  }
}

class _PointStatus extends StatelessWidget {
  const _PointStatus({required this.state});

  final EditProfileState state;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    final IconData icon;
    final Color color;
    final String text;

    if (state.outOfArea) {
      icon = Icons.error_outline_rounded;
      color = Colors.red.shade600;
      text = '${ServiceArea.outOfAreaMessage} Pilih titik di dalam area.';
    } else if (state.point != null) {
      icon = Icons.check_circle_rounded;
      color = AppColors.success;
      text = state.source == LocationSource.typed
          ? 'Titik ditemukan dari alamat. Kurang pas? Pilih di peta.'
          : 'Titik lokasi tersimpan. Kurang pas? Geser di peta.';
    } else if (state.address.trim().length >= 8) {
      icon = Icons.info_outline_rounded;
      color = AppColors.rijikiOrange;
      text = 'Titik belum ditemukan. Pilih di peta agar ongkir akurat.';
    } else {
      return const SizedBox(height: 18);
    }

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 16, color: color),
        const SizedBox(width: 6),
        Expanded(
          child: Text(
            text,
            style: textTheme.bodySmall?.copyWith(
              color: AppColors.onSurfaceVariant,
            ),
          ),
        ),
      ],
    );
  }
}
