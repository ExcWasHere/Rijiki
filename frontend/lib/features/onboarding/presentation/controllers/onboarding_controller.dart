import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:latlong2/latlong.dart';
import 'package:rijiki/app/providers.dart';
import 'package:rijiki/core/error/failure.dart';
import 'package:rijiki/core/location/location_service.dart';
import 'package:rijiki/core/location/service_area.dart';
import 'package:rijiki/core/session/session_provider.dart';
import 'package:rijiki/core/utils/phone_number.dart';

enum LocationSource { none, typed, gps, map }

enum LocateResult {
  success,
  addressNotFound,
  serviceDisabled,
  denied,
  deniedForever,
  unavailable,
  outOfArea,
}

class OnboardingState {
  final int currentPage;
  final String name;
  final String phone;
  final String address;
  final LatLng? point;
  final LocationSource source;
  final bool isLocating;
  final bool isSubmitting;
  final bool outOfArea;

  const OnboardingState({
    this.currentPage = 0,
    this.name = '',
    this.phone = '',
    this.address = '',
    this.point,
    this.source = LocationSource.none,
    this.isLocating = false,
    this.isSubmitting = false,
    this.outOfArea = false,
  });

  OnboardingState copyWith({
    int? currentPage,
    String? name,
    String? phone,
    String? address,
    LatLng? point,
    bool clearPoint = false,
    LocationSource? source,
    bool? isLocating,
    bool? isSubmitting,
    bool? outOfArea,
  }) {
    return OnboardingState(
      currentPage: currentPage ?? this.currentPage,
      name: name ?? this.name,
      phone: phone ?? this.phone,
      address: address ?? this.address,
      point: clearPoint ? null : (point ?? this.point),
      source: source ?? this.source,
      isLocating: isLocating ?? this.isLocating,
      isSubmitting: isSubmitting ?? this.isSubmitting,
      outOfArea: outOfArea ?? this.outOfArea,
    );
  }
}

class OnboardingController extends Notifier<OnboardingState> {
  late final PageController pageController;
  static const int lastPage = 2;

  static const int maxNameLength = 100;
  static const int minAddressLength = 5;
  static const int maxAddressLength = 300;

  Timer? _geocodeDebounce;

  @override
  OnboardingState build() {
    pageController = PageController();
    ref.onDispose(() {
      pageController.dispose();
      _geocodeDebounce?.cancel();
    });
    return const OnboardingState();
  }

  void onPageChanged(int index) {
    debugPrint('onPageChanged: $index');
    if (state.currentPage != index) {
      state = state.copyWith(currentPage: index);
    }
  }

  void nextPage() => goToPage(state.currentPage + 1);
  void previousPage() => goToPage(state.currentPage - 1);

  void goToPage(int page) {
    if (page < 0 || page > lastPage) return;
    if (page == state.currentPage) return;

    state = state.copyWith(currentPage: page);
    if (pageController.hasClients) {
      pageController.jumpToPage(page);
    }
    debugPrint('goToPage: ${state.currentPage} -> $page');
  }

  void reset() {
    _geocodeDebounce?.cancel();
    state = const OnboardingState();
    if (pageController.hasClients) {
      pageController.jumpToPage(0);
    }
  }

  void updateName(String val) {
    state = state.copyWith(name: val);
  }

  void updatePhone(String val) {
    state = state.copyWith(phone: val);
  }

  void updateAddress(String val) {
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

  String? validatePage(int page) {
    switch (page) {
      case 0:
        {
          final name = state.name.trim();
          if (name.isEmpty) return 'Nama belum diisi.';
          if (name.length > maxNameLength) {
            return 'Nama maksimal $maxNameLength karakter.';
          }
          return null;
        }
      case 1:
        {
          if (!PhoneNumber.isValid(state.phone)) {
            return 'Nomor HP belum valid. Contoh: 8123456789';
          }
          return null;
        }
      case 2:
        {
          final address = state.address.trim();
          if (address.length < minAddressLength) {
            return 'Alamat belum diisi lengkap.';
          }
          if (address.length > maxAddressLength) {
            return 'Alamat maksimal $maxAddressLength karakter.';
          }
          if (state.point == null) {
            return state.outOfArea
                ? ServiceArea.outOfAreaMessage
                : 'Titik lokasi belum ditemukan. Pilih di peta agar ongkir akurat.';
          }
          return null;
        }
      default:
        return null;
    }
  }

  String? validateCurrentPage() => validatePage(state.currentPage);

  String? _validateAll() {
    for (var page = 0; page <= lastPage; page++) {
      final error = validatePage(page);
      if (error != null) return error;
    }
    return null;
  }

  Future<void> complete() async {
    if (state.isSubmitting) return;

    final error = _validateAll();
    if (error != null) {
      throw Failure(FailureType.validation, error);
    }

    final current = ref.read(sessionProvider);
    if (current == null) {
      throw const Failure(
        FailureType.unauthorized,
        'Sesi berakhir. Silakan masuk lagi.',
      );
    }

    _geocodeDebounce?.cancel();
    state = state.copyWith(isSubmitting: true);

    try {
      final point = state.point!;
      final user = await ref
          .read(profileRepositoryProvider)
          .saveCustomerProfile(
            currentUser: current,
            fullName: state.name.trim(),
            phoneNumber: PhoneNumber.normalize(state.phone),
            address: state.address.trim(),
            latitude: point.latitude,
            longitude: point.longitude,
          );
      ref.read(sessionProvider.notifier).setUser(user);
    } finally {
      if (ref.mounted) {
        state = state.copyWith(isSubmitting: false);
      }
    }
  }
}

final onboardingControllerProvider =
    NotifierProvider.autoDispose<OnboardingController, OnboardingState>(
      OnboardingController.new,
    );
