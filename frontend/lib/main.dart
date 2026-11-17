import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:rijiki/app/app.dart';
import 'package:rijiki/core/notifications/push_service.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await PushService.initialize();
  runApp(
    ProviderScope(
      retry: (retryCount, error) => null,
      child: const RijikiApp(),
    ),
  );
}
