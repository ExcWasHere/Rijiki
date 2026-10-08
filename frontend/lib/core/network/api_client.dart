import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:http/http.dart' as http;
import 'package:rijiki/core/constants/app_constants.dart';
import 'package:rijiki/core/constants/app_strings.dart';
import 'package:rijiki/core/error/app_exception.dart';
import 'package:rijiki/core/network/api_endpoint.dart';
import 'package:rijiki/core/storage/token_storage.dart';

typedef Json = Map<String, dynamic>;
class ApiClient {
  ApiClient({
    required this.baseUrl,
    required this.tokenStorage,
    this.onSessionExpired,
    http.Client? client,
  }) : _client = client ?? http.Client();

  final String baseUrl;
  final TokenStorage tokenStorage;
  final void Function()? onSessionExpired;

  final http.Client _client;
  Future<bool>? _refreshing;

  Future<Json> get(String path, {bool auth = false}) {
    return _send('GET', path, auth: auth);
  }

  Future<Json> post(String path, {Json? body, bool auth = false}) {
    return _send('POST', path, body: body, auth: auth);
  }

  Future<Json> _send(
    String method,
    String path, {
    Json? body,
    bool auth = false,
    bool isRetry = false,
  }) async {
    final headers = <String, String>{
      'Content-Type': 'application/json',
      'Accept': 'application/json',
    };

    if (auth) {
      final token = await tokenStorage.readAccessToken();
      if (token == null) {
        throw const AppException(
          code: 'unauthorized',
          message: AppStrings.errSessionExpired,
          statusCode: 401,
        );
      }
      headers['Authorization'] = 'Bearer $token';
    }

    final uri = Uri.parse('$baseUrl$path');
    final http.Response response;
    try {
      final request = method == 'GET'
          ? _client.get(uri, headers: headers)
          : _client.post(
              uri,
              headers: headers,
              body: jsonEncode(body ?? <String, dynamic>{}),
            );
      response = await request.timeout(AppConstants.requestTimeout);
    } on TimeoutException {
      throw _networkError();
    } on IOException {
      throw _networkError();
    } on http.ClientException {
      throw _networkError();
    }

    final decoded = _decode(response);
    if (response.statusCode >= 200 && response.statusCode < 300) {
      return decoded;
    }

    if (auth && response.statusCode == 401 && !isRetry) {
      final refreshed = await _refreshTokens();
      if (refreshed) {
        return _send(method, path, body: body, auth: auth, isRetry: true);
      }
    }

    final error = decoded['error'];
    throw AppException(
      code: error is Map ? (error['code'] as String? ?? 'unknown') : 'unknown',
      message: error is Map
          ? (error['message'] as String? ?? AppStrings.errUnknown)
          : AppStrings.errUnknown,
      statusCode: response.statusCode,
    );
  }

  Future<bool> _refreshTokens() {
    return _refreshing ??= _doRefresh().whenComplete(() => _refreshing = null);
  }

  Future<bool> _doRefresh() async {
    final refreshToken = await tokenStorage.readRefreshToken();
    if (refreshToken == null) return false;

    try {
      final json = await _send(
        'POST',
        ApiEndpoints.refresh,
        body: {'refresh_token': refreshToken},
      );
      await tokenStorage.save(
        accessToken: json['access_token'] as String,
        refreshToken: json['refresh_token'] as String,
      );
      return true;
    } on AppException catch (e) {
      if (e.isNetwork) rethrow;
      await tokenStorage.clear();
      onSessionExpired?.call();
      return false;
    }
  }

  Json _decode(http.Response response) {
    if (response.bodyBytes.isEmpty) return <String, dynamic>{};
    try {
      final decoded = jsonDecode(utf8.decode(response.bodyBytes));
      if (decoded is Map<String, dynamic>) return decoded;
    } on FormatException {
    }
    return <String, dynamic>{};
  }

  AppException _networkError() {
    return const AppException(
      code: AppException.networkCode,
      message: AppStrings.errNetwork,
    );
  }
}
