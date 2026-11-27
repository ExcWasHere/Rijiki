import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:rijiki/core/location/location_service.dart';
import 'package:rijiki/core/location/service_area.dart';
import 'package:rijiki/core/theme/app_colors.dart';
import 'package:rijiki/features/onboarding/presentation/controllers/onboarding_controller.dart';
import 'package:rijiki/features/onboarding/presentation/pages/location_picker_page.dart';
import 'package:rijiki/features/onboarding/presentation/widgets/components/background_decorations.dart';
import 'package:rijiki/features/onboarding/presentation/widgets/components/typewriter_chat_bubble.dart';

class StepAddress extends ConsumerStatefulWidget {
  const StepAddress({super.key});

  @override
  ConsumerState<StepAddress> createState() => _StepAddressState();
}

class _StepAddressState extends ConsumerState<StepAddress> {
  late final TextEditingController _address;

  @override
  void initState() {
    super.initState();
    _address = TextEditingController(
      text: ref.read(onboardingControllerProvider).address,
    );
  }

  @override
  void dispose() {
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
        .read(onboardingControllerProvider.notifier)
        .useCurrentLocation();
    if (!mounted) return;
    _report(result);
  }

  Future<void> _pickOnMap() async {
    final state = ref.read(onboardingControllerProvider);
    final picked = await Navigator.of(context).push<PickedLocation>(
      MaterialPageRoute(
        builder: (_) => LocationPickerPage(initialPoint: state.point),
      ),
    );
    if (picked == null || !mounted) return;

    final controller = ref.read(onboardingControllerProvider.notifier);
    controller.applyPickedLocation(picked.point, picked.address);

    final hasAddress = ref
        .read(onboardingControllerProvider)
        .address
        .trim()
        .isNotEmpty;
    if (picked.address == null && !hasAddress) {
      _toast('Alamat titik ini tidak terbaca. Ketik alamat lengkapmu ya.');
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(onboardingControllerProvider);
    final controller = ref.read(onboardingControllerProvider.notifier);
    final keyboardOffset = MediaQuery.viewInsetsOf(context).bottom;
    ref.listen<String>(onboardingControllerProvider.select((s) => s.address), (
      _,
      next,
    ) {
      if (_address.text != next) {
        _address.value = TextEditingValue(
          text: next,
          selection: TextSelection.collapsed(offset: next.length),
        );
      }
    });

    return Stack(
      children: [
        const Positioned(
          left: -35,
          top: -35,
          child: CyanCircleDecoration(width: 160, height: 160),
        ),

        const Positioned(
          left: 0,
          top: 220,
          child: LeftOrangeBlobDecoration(width: 170, height: 270),
        ),

        const Positioned(
          right: -40,
          bottom: 110,
          child: CyanCircleDecoration(width: 170, height: 170),
        ),
        SingleChildScrollView(
          physics: const ClampingScrollPhysics(),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                const SizedBox(height: 40),
                const Text(
                  'Atur\nAlamatmu!',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 36,
                    fontWeight: FontWeight.bold,
                    color: AppColors.onSurface,
                    height: 1.15,
                  ),
                ),
                const SizedBox(height: 42),
                const TypewriterChatBubble(
                  text:
                      'Boleh minta info alamat lengkapmu untuk lokasi pengantaran nanti?',
                ),
                const SizedBox(height: 230),
                Transform.translate(
                  offset: Offset(0, -keyboardOffset),
                  child: Column(
                    children: [
                      Container(
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(30),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.04),
                              blurRadius: 10,
                              offset: const Offset(0, 3),
                            ),
                          ],
                        ),
                        child: TextFormField(
                          controller: _address,
                          onChanged: controller.updateAddress,
                          minLines: 1,
                          maxLines: 3,
                          keyboardType: TextInputType.streetAddress,
                          textCapitalization: TextCapitalization.words,
                          style: const TextStyle(
                            fontSize: 13,
                            color: AppColors.onSurface,
                          ),
                          decoration: InputDecoration(
                            hintText:
                                'Cari nama jalan, gedung, atau perumahan...',
                            hintStyle: const TextStyle(
                              fontSize: 13,
                              color: Color(0xFFA0A0A0),
                            ),
                            prefixIcon: const Padding(
                              padding: EdgeInsets.only(left: 14, right: 8),
                              child: Icon(
                                Icons.location_on_outlined,
                                color: AppColors.rijikiBlue,
                                size: 22,
                              ),
                            ),
                            prefixIconConstraints: const BoxConstraints(
                              minWidth: 40,
                              minHeight: 40,
                            ),
                            filled: true,
                            fillColor: Colors.white,
                            contentPadding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 14,
                            ),
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(30),
                              borderSide: const BorderSide(
                                color: Color(0xFFCCCCCC),
                                width: 1.0,
                              ),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(30),
                              borderSide: const BorderSide(
                                color: AppColors.rijikiBlue,
                                width: 1.8,
                              ),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 8),
                      _PointStatus(state: state),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          Expanded(
                            child: _LocationButton(
                              icon: Icons.my_location_rounded,
                              label: 'Lokasi saya',
                              loading: state.isLocating,
                              onPressed: state.isLocating
                                  ? null
                                  : _useMyLocation,
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: _LocationButton(
                              icon: Icons.map_outlined,
                              label: 'Pilih di peta',
                              onPressed: _pickOnMap,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),
              ],
            ),
          ),
        ),
      ],
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

  final OnboardingState state;

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
