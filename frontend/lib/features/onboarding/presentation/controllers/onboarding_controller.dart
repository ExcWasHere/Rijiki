import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:rijiki/core/session/session_provider.dart';

class OnboardingState {
  final int currentPage;
  final String name;
  final String phone;
  final String address;
  final Set<String> selectedProblems;

  const OnboardingState({
    this.currentPage = 0,
    this.name = '',
    this.phone = '',
    this.address = '',
    this.selectedProblems = const {},
  });

  OnboardingState copyWith({
    int? currentPage,
    String? name,
    String? phone,
    String? address,
    Set<String>? selectedProblems,
  }) {
    return OnboardingState(
      currentPage: currentPage ?? this.currentPage,
      name: name ?? this.name,
      phone: phone ?? this.phone,
      address: address ?? this.address,
      selectedProblems: selectedProblems ?? this.selectedProblems,
    );
  }
}

class OnboardingController extends Notifier<OnboardingState> {
  late final PageController pageController;
  static const int lastPage = 6;

  @override
  OnboardingState build() {
    pageController = PageController();
    ref.onDispose(pageController.dispose);
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

  void updateName(String val) {
    state = state.copyWith(name: val);
  }

  void updatePhone(String val) {
    state = state.copyWith(phone: val);
  }

  void updateAddress(String val) {
    state = state.copyWith(address: val);
  }

  void toggleProblem(String problem) {
    final current = Set<String>.from(state.selectedProblems);
    if (current.contains(problem)) {
      current.remove(problem);
    } else {
      current.add(problem);
    }
    state = state.copyWith(selectedProblems: current);
  }
  // TODO(backend): kirim name, phone, address (default_address) ke API
  // onboarding sebelum menandai selesai.
  Future<void> complete() async {
    ref.read(sessionProvider.notifier).completeProfile(
          fullName: state.name.trim(),
          phoneNumber: state.phone.trim(),
        );
  }
}

final onboardingControllerProvider =
    NotifierProvider<OnboardingController, OnboardingState>(
      OnboardingController.new,
    );
