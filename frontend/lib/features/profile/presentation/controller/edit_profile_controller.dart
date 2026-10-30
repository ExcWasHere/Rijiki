import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:latlong2/latlong.dart';
import 'package:rijiki/app/providers.dart';
import 'package:rijiki/core/enums/user_role.dart';
import 'package:rijiki/core/error/failure.dart';
import 'package:rijiki/core/location/location_service.dart';
import 'package:rijiki/core/location/service_area.dart';
import 'package:rijiki/core/session/app_user.dart';
import 'package:rijiki/core/session/session_provider.dart';
import 'package:rijiki/core/utils/phone_number.dart';
import 'package:rijiki/features/onboarding/presentation/controllers/onboarding_controller.dart'
    show LocateResult, LocationSource;

class EditProfileState {
  const EditProfileState({
    required this.name,
    required this.phone,
    this.address = '',
    this.point,
    this.source = LocationSource.none,
    this.avatarPath,
    this.isLocating = false,
    this.isSubmitting = false,
    this.outOfArea = false,
  });

  final String name;

  /// Nomor HP versi input (tanpa awalan 62/0), mis. 8123456789.
  final String phone;
  final String address;
  final LatLng? point;
  final LocationSource source;

  /// Path foto baru yang belum diunggah. null = avatar tidak diganti.
  final String? avatarPath;
  final bool isLocating;
  final bool isSubmitting;
  final bool outOfArea;

  EditProfileState copyWith({
    String? name,
    String? phone,
    String? address,
    LatLng? point,
    bool clearPoint = false,
    LocationSource? source,
    String? avatarPath,
    bool clearAvatar = false,
    bool? isLocating,
    bool? isSubmitting,
    bool? outOfArea,
  }) {
    return EditProfileState(
      name: name ?? this.name,
      phone: phone ?? this.phone,
      address: address ?? this.address,
      point: clearPoint ? null : (point ?? this.point),
      source: source ?? this.source,
      avatarPath: clearAvatar ? null : (avatarPath ?? this.avatarPath),
      isLocating: isLocating ?? this.isLocating,
      isSubmitting: isSubmitting ?? this.isSubmitting,
      outOfArea: outOfArea ?? this.outOfArea,
    );
  }

  /// Apakah teks (nama, HP, alamat/titik) berbeda dari data di sesi.
  bool textChanged(AppUser user) {
    if (name.trim() != (user.fullName ?? '').trim()) return true;
    if (PhoneNumber.normalize(phone) !=
        PhoneNumber.normalize(user.phoneNumber ?? '')) {
      return true;
    }
    if (user.role == UserRole.customer) {
      if (address.trim() != (user.defaultAddress ?? '').trim()) return true;
      if (point?.latitude != user.defaultLat ||
          point?.longitude != user.defaultLng) {
        return true;
      }
    }
    return false;
  }

  bool hasChanges(AppUser user) => avatarPath != null || textChanged(user);
}

class EditProfileController extends Notifier<EditProfileState> {
  static const int maxNameLength = 100;
  static const int minAddressLength = 5;
  static const int maxAddressLength = 300;

  Timer? _geocodeDebounce;

  @override
  EditProfileState build() {
    ref.onDispose(() => _geocodeDebounce?.cancel());

    final user = ref.read(sessionProvider);
    final lat = user?.defaultLat;
    final lng = user?.defaultLng;
    final hasPoint = lat != null && lng != null;

    return EditProfileState(
      name: user?.fullName?.trim() ?? '',
      phone: phoneInputOf(user?.phoneNumber),
      address: user?.defaultAddress ?? '',
      point: hasPoint ? LatLng(lat, lng) : null,
      source: hasPoint ? LocationSource.map : LocationSource.none,
    );
  }

  /// "+6281234567890" / "6281234567890" / "081234567890" -> "81234567890".
  static String phoneInputOf(String? raw) {
    final digits = (raw ?? '').replaceAll(RegExp(r'\D'), '');
    if (digits.startsWith('62')) return digits.substring(2);
    if (digits.startsWith('0')) return digits.substring(1);
    return digits;
  }

  // ---- Validator (dipakai Form di halaman dan save()) ----

  static String? validateName(String? value) {
    final name = value?.trim() ?? '';
    if (name.isEmpty) return 'Nama belum diisi.';
    if (name.length > maxNameLength) {
      return 'Nama maksimal $maxNameLength karakter.';
    }
    return null;
  }

  static String? validatePhone(String? value) {
    if (!PhoneNumber.isValid(value ?? '')) {
      return 'Nomor HP belum valid. Contoh: 8123456789';
    }
    return null;
  }

  static String? validateAddress(String? value) {
    final address = value?.trim() ?? '';
    if (address.length < minAddressLength) return 'Alamat belum diisi lengkap.';
    if (address.length > maxAddressLength) {
      return 'Alamat maksimal $maxAddressLength karakter.';
    }
    return null;
  }

  // ---- Perubahan field ----

  void updateName(String val) {
    if (state.name == val) return;
    state = state.copyWith(name: val);
  }

  void updatePhone(String val) {
    if (state.phone == val) return;
    state = state.copyWith(phone: val);
  }

  void setAvatar(String path) {
    state = state.copyWith(avatarPath: path);
  }

  void updateAddress(String val) {
    if (state.address == val) return;
    state = state.copyWith(address: val);

    if (state.source == LocationSource.gps ||
        state.source == LocationSource.map) {
      return;
    }

    _geocodeDebounce?.cancel();
    final text = val.trim();
    if (text.length < 8) {
      state = state.copyWith(
        clearPoint: true,
        source: LocationSource.none,
        outOfArea: false,
      );
      return;
    }
    _geocodeDebounce = Timer(
      const Duration(milliseconds: 900),
      () => _geocodeTyped(text),
    );
  }

  Future<void> _geocodeTyped(String text) async {
    final point = await ref.read(locationServiceProvider).pointOf(text);
    if (!ref.mounted) return;
    if (state.address.trim() != text) return;
    if (state.source == LocationSource.gps ||
        state.source == LocationSource.map) {
      return;
    }

    if (point == null) {
      state = state.copyWith(
        clearPoint: true,
        source: LocationSource.none,
        outOfArea: false,
      );
      return;
    }
    if (!ServiceArea.contains(point)) {
      state = state.copyWith(
        clearPoint: true,
        source: LocationSource.none,
        outOfArea: true,
      );
      return;
    }
    state = state.copyWith(
      point: point,
      source: LocationSource.typed,
      outOfArea: false,
    );
  }

  Future<LocateResult> useCurrentLocation() async {
    if (state.isLocating) return LocateResult.success;
    _geocodeDebounce?.cancel();
    state = state.copyWith(isLocating: true);

    final service = ref.read(locationServiceProvider);
    try {
      final point = await service.currentPoint();
      if (!ref.mounted) return LocateResult.success;

      if (!ServiceArea.contains(point)) {
        state = state.copyWith(isLocating: false);
        return LocateResult.outOfArea;
      }

      final address = await service.addressOf(point);
      if (!ref.mounted) return LocateResult.success;

      state = state.copyWith(
        point: point,
        source: LocationSource.gps,
        address: address ?? state.address,
        isLocating: false,
        outOfArea: false,
      );
      return address == null
          ? LocateResult.addressNotFound
          : LocateResult.success;
    } on LocationException catch (e) {
      if (!ref.mounted) return LocateResult.unavailable;
      state = state.copyWith(isLocating: false);
      return switch (e.issue) {
        LocationIssue.serviceDisabled => LocateResult.serviceDisabled,
        LocationIssue.denied => LocateResult.denied,
        LocationIssue.deniedForever => LocateResult.deniedForever,
        LocationIssue.unavailable => LocateResult.unavailable,
      };
    }
  }

  void applyPickedLocation(LatLng point, String? address) {
    _geocodeDebounce?.cancel();
    if (!ServiceArea.contains(point)) {
      state = state.copyWith(outOfArea: true);
      return;
    }
    state = state.copyWith(
      point: point,
      source: LocationSource.map,
      outOfArea: false,
      address: (address == null || address.trim().isEmpty)
          ? state.address
          : address,
    );
  }

  // ---- Simpan ----

  String? _validateAll({required bool isCustomer}) {
    final error = validateName(state.name) ?? validatePhone(state.phone);
    if (error != null) return error;
    if (!isCustomer) return null;

    final addressError = validateAddress(state.address);
    if (addressError != null) return addressError;
    if (state.point == null) {
      return state.outOfArea
          ? ServiceArea.outOfAreaMessage
          : 'Titik lokasi belum ditemukan. Pilih di peta agar ongkir akurat.';
    }
    return null;
  }

  /// Menyimpan teks lebih dulu, lalu avatar. Bila avatar gagal setelah teks
  /// berhasil, sesi sudah terbarui dan state avatar tetap ada agar bisa
  /// dicoba lagi tanpa mengirim ulang teks.
  Future<void> save() async {
    if (state.isSubmitting) return;

    final current = ref.read(sessionProvider);
    if (current == null) {
      throw const Failure(
        FailureType.unauthorized,
        'Sesi berakhir. Silakan masuk lagi.',
      );
    }

    final isCustomer = current.role == UserRole.customer;
    final error = _validateAll(isCustomer: isCustomer);
    if (error != null) throw Failure(FailureType.validation, error);
    if (!state.hasChanges(current)) return;

    _geocodeDebounce?.cancel();
    state = state.copyWith(isSubmitting: true);

    try {
      final repository = ref.read(profileRepositoryProvider);
      final session = ref.read(sessionProvider.notifier);
      var user = current;

      if (state.textChanged(current)) {
        final phone = PhoneNumber.normalize(state.phone);
        if (isCustomer) {
          final point = state.point!;
          user = await repository.saveCustomerProfile(
            currentUser: user,
            fullName: state.name.trim(),
            phoneNumber: phone,
            address: state.address.trim(),
            latitude: point.latitude,
            longitude: point.longitude,
          );
        } else {
          user = await repository.saveProfile(
            currentUser: user,
            fullName: state.name.trim(),
            phoneNumber: phone,
          );
        }
        session.setUser(user);
      }

      final avatarPath = state.avatarPath;
      if (avatarPath != null) {
        user = await repository.uploadAvatar(
          currentUser: user,
          filePath: avatarPath,
        );
        session.setUser(user);
        if (ref.mounted) state = state.copyWith(clearAvatar: true);
      }
    } finally {
      if (ref.mounted) state = state.copyWith(isSubmitting: false);
    }
  }
}

final editProfileControllerProvider =
    NotifierProvider.autoDispose<EditProfileController, EditProfileState>(
      EditProfileController.new,
    );
