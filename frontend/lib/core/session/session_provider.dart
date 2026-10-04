import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:rijiki/core/session/app_user.dart';

class SessionNotifier extends Notifier<AppUser?> {
  @override
  AppUser? build() => null;

  void setUser(AppUser? user) => state = user;

  void clear() => state = null;
}

final sessionProvider = NotifierProvider<SessionNotifier, AppUser?>(
  SessionNotifier.new,
);
