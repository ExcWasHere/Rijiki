import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:rijiki/core/session/app_user.dart';

class SessionNotifier extends Notifier<AppUser?> {
  @override
  AppUser? build() => null;

  void setUser(AppUser? user) => state = user;

  void clear() => state = null;
  void completeProfile({
    required String fullName,
    required String phoneNumber,
  }) {
    final current = state;
    if (current == null) return;
    state = current.copyWith(
      fullName: fullName,
      phoneNumber: phoneNumber,
      profileCompleted: true,
    );
  }
}

final sessionProvider = NotifierProvider<SessionNotifier, AppUser?>(
  SessionNotifier.new,
);
