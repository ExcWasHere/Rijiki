import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:rijiki/app/app.dart';

void main() {
  runApp(
    ProviderScope(
      retry: (retryCount, error) => null,
      child: const RijikiApp(),
    ),
  );
}
