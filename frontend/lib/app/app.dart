import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:rijiki/app/providers.dart';
import 'package:rijiki/app/router/app_router.dart';
import 'package:rijiki/app/router/role_redirect.dart';
import 'package:rijiki/app/router/route_paths.dart';
import 'package:rijiki/core/constants/app_strings.dart';
import 'package:rijiki/core/session/app_user.dart';
import 'package:rijiki/core/session/session_provider.dart';
import 'package:rijiki/core/theme/app_theme.dart';
import 'package:rijiki/features/notifications/presentation/controllers/notification_list_controller.dart';
import 'package:rijiki/features/notifications/presentation/utils/notification_route.dart';

class RijikiApp extends ConsumerStatefulWidget {
  const RijikiApp({super.key});

  @override
  ConsumerState<RijikiApp> createState() => _RijikiAppState();
}

class _RijikiAppState extends ConsumerState<RijikiApp> {
  StreamSubscription<Map<String, dynamic>>? _tapSub;

  /// Push yang diketuk tetapi belum bisa dibuka (masih splash, belum login,
  /// atau onboarding belum selesai).
  Map<String, dynamic>? _pendingTap;

  @override
  void initState() {
    super.initState();
    _tapSub = ref.read(pushServiceProvider).taps.listen(_queueTap);
    ref.read(appRouterProvider).routerDelegate.addListener(_flushTap);
  }

  @override
  void dispose() {
    _tapSub?.cancel();
    ref.read(appRouterProvider).routerDelegate.removeListener(_flushTap);
    super.dispose();
  }

  void _queueTap(Map<String, dynamic> data) {
    _pendingTap = data;
    _flushTap();
  }

  void _flushTap() {
    final data = _pendingTap;
    final user = ref.read(sessionProvider);
    if (data == null || user == null || RoleRedirect.needsOnboarding(user)) {
      return;
    }

    final router = ref.read(appRouterProvider);
    final location = router.routerDelegate.currentConfiguration.uri.path;
    // Splash akan mengganti rute dengan `go`; tunggu sampai selesai.
    if (location == RoutePaths.splash) return;

    _pendingTap = null;
    openPushData(router, user.role, data);
  }

  @override
  Widget build(BuildContext context) {
    // Satu tempat untuk mendaftarkan/melepas token FCM mengikuti sesi:
    // login atau sesi pulih -> daftar; keluar -> lepas.
    ref.listen<AppUser?>(sessionProvider, (previous, next) {
      final push = ref.read(pushServiceProvider);
      if (next == null) {
        if (previous != null) unawaited(push.stop());
        return;
      }
      if (previous?.id == next.id) return;
      unawaited(
        push.start(
          onMessage: () {
            ref.invalidate(unreadNotificationCountProvider);
            ref.invalidate(notificationListProvider);
          },
        ),
      );
      unawaited(
        push.takeLaunchData().then((data) {
          if (data != null && mounted) _queueTap(data);
        }),
      );
      _flushTap();
    });

    return MaterialApp.router(
      title: AppStrings.appName,
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light,
      routerConfig: ref.watch(appRouterProvider),
    );
  }
}
