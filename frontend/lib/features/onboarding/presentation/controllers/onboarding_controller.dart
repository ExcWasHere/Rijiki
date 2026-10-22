import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:latlong2/latlong.dart';
import 'package:rijiki/app/providers.dart';
import 'package:rijiki/core/location/default_location.dart';
import 'package:rijiki/core/location/location_service.dart';
import 'package:rijiki/core/session/session_provider.dart';

enum LocationSource { none, typed, gps, map }

enum LocateResult {
  success,
  addressNotFound,
  serviceDisabled,
  denied,
  deniedForever,
  unavailable,
}

class OnboardingState {
  final int currentPage;
  final String name;
  final String phone;
  final String address;
  final LatLng? point;
  final LocationSource source;
  final bool isLocating;

  const OnboardingState({
    this.currentPage = 0,
    this.name = '',
    this.phone = '',
    this.address = '',
    this.point,
    this.source = LocationSource.none,
    this.isLocating = false,
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
  }) {
    return OnboardingState(
      currentPage: currentPage ?? this.currentPage,
      name: name ?? this.name,
      phone: phone ?? this.phone,
      address: address ?? this.address,
      point: clearPoint ? null : (point ?? this.point),
      source: source ?? this.source,
      isLocating: isLocating ?? this.isLocating,
    );
  }
}

class OnboardingController extends Notifier<OnboardingState> {
  late final PageController pageController;
  static const int lastPage = 2;

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
      state = state.copyWith(clearPoint: true, source: LocationSource.none);
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
    state = point == null
        ? state.copyWith(clearPoint: true, source: LocationSource.none)
        : state.copyWith(point: point, source: LocationSource.typed);
  }

  Future<LocateResult> useCurrentLocation() async {
    if (state.isLocating) return LocateResult.success;
    _geocodeDebounce?.cancel();
    state = state.copyWith(isLocating: true);

    final service = ref.read(locationServiceProvider);
    try {
      final point = await service.currentPoint();
      final address = await service.addressOf(point);
      if (!ref.mounted) return LocateResult.success;

      state = state.copyWith(
        point: point,
        source: LocationSource.gps,
        address: address ?? state.address,
        isLocating: false,
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
    state = state.copyWith(
      point: point,
      source: LocationSource.map,
      address: (address == null || address.trim().isEmpty)
          ? state.address
          : address,
    );
  }

  // TODO(backend): kirim name, phone, address, dan koordinat
  // (default_address, default_lat, default_lng) ke API profil.
  Future<void> complete() async {
    final address = state.address.trim();
    var point = state.point;
    if (point == null && address.isNotEmpty) {
      point = await ref.read(locationServiceProvider).pointOf(address);
    }

    await ref.read(tokenStorageProvider).setOnboardingCompleted(true);
    ref
        .read(defaultLocationProvider.notifier)
        .set(DefaultLocation(address: address, point: point));
    ref.read(sessionProvider.notifier).completeProfile(
          fullName: state.name.trim(),
          phoneNumber: state.phone.trim(),
        );
    reset();
  }
}

final onboardingControllerProvider =
    NotifierProvider.autoDispose<OnboardingController, OnboardingState>(
      OnboardingController.new,
    );
