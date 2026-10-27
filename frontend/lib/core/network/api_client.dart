import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/foundation.dart';
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

  static const Duration uploadTimeout = Duration(seconds: 60);

  Future<Json> get(String path, {bool auth = false}) {
    return _send('GET', path, auth: auth);
  }

  Future<Json> post(String path, {Json? body, bool auth = false}) {
    return _send('POST', path, body: body, auth: auth);
  }

  Future<Json> patch(String path, {Json? body, bool auth = false}) {
    return _send('PATCH', path, body: body, auth: auth);
  }

  Future<Json> delete(String path, {bool auth = false}) {
    return _send('DELETE', path, auth: auth);
  }

  Future<Uint8List> getBytes(String path, {bool auth = false}) async {
    final response = await _request(
      method: 'GET',
      path: path,
      auth: auth,
      send: (uri, headers) => _client.get(uri, headers: headers),
    );
    return response.bodyBytes;
  }

  Future<Json> postMultipart(
    String path, {
    required Map<String, String> fields,
    required String fileField,
    required String filePath,
    bool auth = false,
  }) async {
    final response = await _request(
      method: 'POST',
      path: path,
      auth: auth,
      timeout: uploadTimeout,
      send: (uri, headers) async {
        final request = http.MultipartRequest('POST', uri)
          ..headers.addAll(headers)
          ..fields.addAll(fields)
          ..files.add(await http.MultipartFile.fromPath(fileField, filePath));
        return http.Response.fromStream(await _client.send(request));
      },
    );
    return _decode(response);
  }

  Future<Json> _send(
    String method,
    String path, {
    Json? body,
    bool auth = false,
  }) async {
    final response = await _request(
      method: method,
      path: path,
      auth: auth,
      send: (uri, headers) {
        final jsonHeaders = {...headers, 'Content-Type': 'application/json'};
        final encoded = jsonEncode(body ?? <String, dynamic>{});
        return switch (method) {
          'GET' => _client.get(uri, headers: headers),
          'DELETE' => _client.delete(uri, headers: headers),
          'PATCH' => _client.patch(uri, headers: jsonHeaders, body: encoded),
          _ => _client.post(uri, headers: jsonHeaders, body: encoded),
        };
      },
    );
    return _decode(response);
  }

  Future<http.Response> _request({
    required String method,
    required String path,
    required bool auth,
    required Future<http.Response> Function(Uri uri, Map<String, String> headers)
    send,
    Duration? timeout,
    bool isRetry = false,
  }) async {
    final headers = <String, String>{'Accept': 'application/json'};

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
      response = await send(
        uri,
        headers,
      ).timeout(timeout ?? AppConstants.requestTimeout);
    } on TimeoutException catch (e) {
      _logNetworkFailure(method, uri, e);
      throw _networkError();
    } on IOException catch (e) {
      _logNetworkFailure(method, uri, e);
      throw _networkError();
    } on http.ClientException catch (e) {
      _logNetworkFailure(method, uri, e);
      throw _networkError();
    }

    if (response.statusCode >= 200 && response.statusCode < 300) {
      return response;
    }

    if (auth && response.statusCode == 401 && !isRetry) {
      final refreshed = await _refreshTokens();
      if (refreshed) {
        return _request(
          method: method,
          path: path,
          auth: auth,
          send: send,
          timeout: timeout,
          isRetry: true,
        );
      }
    }

    final decoded = _decode(response);
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

  void _logNetworkFailure(String method, Uri uri, Object error) {
    if (!kDebugMode) return;
    debugPrint(
      '[ApiClient] $method $uri gagal -> ${error.runtimeType}: $error',
    );
  }

  AppException _networkError() {
    return const AppException(
      code: AppException.networkCode,
      message: AppStrings.errNetwork,
    );
  }
}
