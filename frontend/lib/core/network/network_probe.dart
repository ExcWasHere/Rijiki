import 'dart:async';
import 'dart:io';

import 'package:flutter/foundation.dart';

abstract final class NetworkProbe {
  static bool _ran = false;

  static Future<void> runOnce(Uri uri) async {
    if (!kDebugMode || _ran) return;
    _ran = true;
    await run(uri);
  }

  static void _log(String message) => debugPrint('[NetworkProbe] $message');

  static Future<void> run(Uri uri) async {
    final host = uri.host;
    final port = uri.hasPort ? uri.port : (uri.scheme == 'https' ? 443 : 80);
    _log('mulai uji $host:$port');

    final dns = Stopwatch()..start();
    final List<InternetAddress> addresses;
    try {
      addresses = await InternetAddress.lookup(
        host,
      ).timeout(const Duration(seconds: 8));
      final list = addresses
          .map(
            (a) =>
                '${a.address}${a.type == InternetAddressType.IPv6 ? ' [IPv6]' : ''}',
          )
          .join(', ');
      _log('DNS ok (${dns.elapsedMilliseconds} ms): $list');
    } on Object catch (e) {
      _log('DNS GAGAL (${dns.elapsedMilliseconds} ms): ${e.runtimeType}: $e');
      return;
    }

    for (final address in addresses) {
      final tcp = Stopwatch()..start();
      try {
        final socket = await Socket.connect(
          address,
          port,
          timeout: const Duration(seconds: 6),
        );
        _log('TCP ok ke ${address.address} (${tcp.elapsedMilliseconds} ms)');
        socket.destroy();
      } on Object catch (e) {
        _log(
          'TCP GAGAL ke ${address.address} (${tcp.elapsedMilliseconds} ms): '
          '${e.runtimeType}: $e',
        );
      }
    }

    if (uri.scheme == 'https') {
      for (final address in addresses) {
        final tls = Stopwatch()..start();
        try {
          final socket = await SecureSocket.connect(
            address,
            port,
            timeout: const Duration(seconds: 8),
          );
          _log('TLS ok ke ${address.address} (${tls.elapsedMilliseconds} ms)');
          socket.destroy();
        } on Object catch (e) {
          _log(
            'TLS GAGAL ke ${address.address} (${tls.elapsedMilliseconds} ms): '
            '${e.runtimeType}: $e',
          );
        }
      }
    }

    final http = Stopwatch()..start();
    final client = HttpClient()
      ..connectionTimeout = const Duration(seconds: 8);
    try {
      final request = await client.getUrl(uri.replace(path: '/'));
      final response = await request.close().timeout(
        const Duration(seconds: 8),
      );
      _log('HTTP ${response.statusCode} (${http.elapsedMilliseconds} ms)');
      await response.drain<void>();
    } on Object catch (e) {
      _log('HTTP GAGAL (${http.elapsedMilliseconds} ms): ${e.runtimeType}: $e');
    } finally {
      client.close(force: true);
    }
    _log('selesai');
  }
}
