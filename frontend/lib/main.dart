import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:rijiki/app/app.dart';
import 'package:rijiki/core/constants/app_constants.dart';
import 'package:rijiki/core/notifications/push_service.dart';

Future<void> main() async {
  if (kReleaseMode &&
      (!AppConstants.apiBaseUrl.startsWith('https://') ||
          AppConstants.googleServerClientId.isEmpty)) {
    throw StateError(
      'Build release tidak valid: API_BASE_URL harus diawali https:// dan '
      'GOOGLE_SERVER_CLIENT_ID wajib diisi. Jalankan '
      'tool/build_release.ps1 atau tool/build_release.sh.',
    );
  }

  WidgetsFlutterBinding.ensureInitialized();
  await PushService.initialize();
  runApp(
    ProviderScope(
      retry: (retryCount, error) => null,
      child: const RijikiApp(),
    ),
  );
}
