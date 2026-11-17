import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:rijiki/app/providers.dart';
import 'package:rijiki/app/router/app_router.dart';
import 'package:rijiki/core/constants/app_strings.dart';
import 'package:rijiki/core/session/app_user.dart';
import 'package:rijiki/core/session/session_provider.dart';
import 'package:rijiki/core/theme/app_theme.dart';
import 'package:rijiki/features/notifications/presentation/controllers/notification_list_controller.dart';

class RijikiApp extends ConsumerStatefulWidget {
  const RijikiApp({super.key});

  @override
  ConsumerState<RijikiApp> createState() => _RijikiAppState();
}

class _RijikiAppState extends ConsumerState<RijikiApp> {
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
    });

    return MaterialApp.router(
      title: AppStrings.appName,
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light,
      routerConfig: ref.watch(appRouterProvider),
    );
  }
}
