import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:rijiki/app/router/app_router.dart';
import 'package:rijiki/core/constants/app_strings.dart';
import 'package:rijiki/core/theme/app_theme.dart';

class RijikiApp extends ConsumerWidget {
  const RijikiApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return MaterialApp.router(
      title: AppStrings.appName,
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light,
      routerConfig: ref.watch(appRouterProvider),
    );
  }
}
