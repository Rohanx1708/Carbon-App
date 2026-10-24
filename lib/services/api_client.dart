import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/foundation.dart';

import 'package:attendance/services/app_config.dart';
import 'package:attendance/services/local_storage_service.dart';
import 'package:attendance/services/storage_keys.dart';

/// Shared HTTP client: connection reuse, timeouts, auth, and errors.
class ApiClient {
  ApiClient({LocalStorageService? storage}) : _storage = storage ?? LocalStorageService.instance;

  final LocalStorageService _storage;
  HttpClient? _client;

  static const Duration _timeout = Duration(seconds: 30);

  HttpClient get _http {
    return _client ??= HttpClient()
      ..connectionTimeout = _timeout
      ..idleTimeout = const Duration(seconds: 15);
  }

  Future<Map<String, dynamic>> getJson(String path, {Map<String, String>? queryParameters, bool authenticated = true}) {
    return _request(method: 'GET', path: path, queryParameters: queryParameters, authenticated: authenticated);
  }

  Future<Map<String, dynamic>> postJson(String path, {Map<String, dynamic>? body, bool authenticated = true}) {
    return _request(method: 'POST', path: path, body: body, authenticated: authenticated);
  }

  Future<Map<String, dynamic>> putJson(String path, {Map<String, dynamic>? body, bool authenticated = true}) {
    return _request(method: 'PUT', path: path, body: body, authenticated: authenticated);
  }

  Future<Map<String, dynamic>> deleteJson(String path, {bool authenticated = true}) {
    return _request(method: 'DELETE', path: path, authenticated: authenticated);
  }

  /// Multipart POST (e.g. profile avatar). [fileField] is the form field name.
  Future<Map<String, dynamic>> postMultipartFile(
    String path, {
    required String fileField,
    required String filePath,
    required String filename,
    String? mimeType,
    Map<String, String>? fields,
    bool authenticated = true,
    int maxFileBytes = 5 * 1024 * 1024,
  }) async {
    final baseUrl = AppConfig.baseUrl.trim();
    if (baseUrl.isEmpty) {
      throw Exception('BASE_URL is not configured');
    }

    final uri = Uri.parse(baseUrl).resolve(path);
    if (kDebugMode) {
      debugPrint('[ApiClient] POST (multipart) $uri');
    }

    final file = File(filePath);
    if (!await file.exists()) {
      throw Exception('File not found');
    }
    final bytes = await file.readAsBytes();
    if (bytes.length > maxFileBytes) {
      final mb = (maxFileBytes / (1024 * 1024)).round();
      throw Exception('File must be $mb MB or smaller');
    }

    final resolvedMime = mimeType ?? _mimeFromFilename(filename);
    final boundary = 'dart-boundary-${DateTime.now().microsecondsSinceEpoch}';

    final req = await _http.postUrl(uri);
    req.headers.set(HttpHeaders.acceptHeader, 'application/json');
    req.headers.set(HttpHeaders.contentTypeHeader, 'multipart/form-data; boundary=$boundary');

    if (authenticated) {
      final token = await _storage.getString(StorageKeys.authToken);
      final tokenType = (await _storage.getString(StorageKeys.authTokenType)) ?? 'Bearer';
      if (token == null || token.trim().isEmpty) {
        throw Exception('Not authenticated');
      }
      req.headers.set(HttpHeaders.authorizationHeader, '$tokenType $token');
    }

    final body = BytesBuilder();
    void writeString(String s) => body.add(utf8.encode(s));

    for (final entry in (fields ?? const {}).entries) {
      writeString('--$boundary\r\n');
      writeString('Content-Disposition: form-data; name="${entry.key}"\r\n\r\n');
      writeString('${entry.value}\r\n');
    }

    writeString('--$boundary\r\n');
    writeString('Content-Disposition: form-data; name="$fileField"; filename="$filename"\r\n');
    writeString('Content-Type: $resolvedMime\r\n\r\n');
    body.add(bytes);
    writeString('\r\n');
    writeString('--$boundary--\r\n');

    req.add(body.takeBytes());

    try {
      final res = await req.close().timeout(_timeout);
      final raw = await res.transform(utf8.decoder).join().timeout(_timeout);

      if (res.statusCode < 200 || res.statusCode >= 300) {
        _throwHttpError(res.statusCode, raw, path);
      }

      final decoded = jsonDecode(raw);
      if (decoded is! Map<String, dynamic>) {
        throw Exception('Invalid response');
      }
      return decoded;
    } on SocketException {
      throw Exception('Network error');
    } on TimeoutException {
      throw Exception('Request timed out');
    }
  }

  static String _mimeFromFilename(String filename) {
    final lower = filename.toLowerCase();
    if (lower.endsWith('.png')) return 'image/png';
    if (lower.endsWith('.webp')) return 'image/webp';
    if (lower.endsWith('.jpg') || lower.endsWith('.jpeg')) return 'image/jpeg';
    return 'application/octet-stream';
  }

  Future<Map<String, dynamic>> _request({
    required String method,
    required String path,
    Map<String, String>? queryParameters,
    Map<String, dynamic>? body,
    bool authenticated = true,
  }) async {
    final baseUrl = AppConfig.baseUrl.trim();
    if (baseUrl.isEmpty) {
      throw Exception('BASE_URL is not configured');
    }

    var uri = Uri.parse(baseUrl).resolve(path);
    if (queryParameters != null && queryParameters.isNotEmpty) {
      uri = uri.replace(queryParameters: queryParameters);
    }

    if (kDebugMode) {
      debugPrint('[ApiClient] $method $uri');
    }

    late final HttpClientRequest req;
    switch (method) {
      case 'GET':
        req = await _http.getUrl(uri);
        break;
      case 'POST':
        req = await _http.postUrl(uri);
        break;
      case 'PUT':
        req = await _http.putUrl(uri);
        break;
      case 'DELETE':
        req = await _http.deleteUrl(uri);
        break;
      default:
        throw Exception('Unsupported method: $method');
    }

    req.headers.set(HttpHeaders.acceptHeader, 'application/json');
    if (body != null) {
      req.headers.set(HttpHeaders.contentTypeHeader, 'application/json');
    }

    if (authenticated) {
      final token = await _storage.getString(StorageKeys.authToken);
      final tokenType = (await _storage.getString(StorageKeys.authTokenType)) ?? 'Bearer';
      if (token == null || token.trim().isEmpty) {
        throw Exception('Not authenticated');
      }
      req.headers.set(HttpHeaders.authorizationHeader, '$tokenType $token');
    }

    if (body != null) {
      req.add(utf8.encode(jsonEncode(body)));
    }

    try {
      final res = await req.close().timeout(_timeout);
      final raw = await res.transform(utf8.decoder).join().timeout(_timeout);

      if (res.statusCode < 200 || res.statusCode >= 300) {
        _throwHttpError(res.statusCode, raw, path);
      }

      final decoded = jsonDecode(raw);
      if (decoded is! Map<String, dynamic>) {
        throw Exception('Invalid response');
      }
      return decoded;
    } on SocketException {
      throw Exception('Network error');
    } on TimeoutException {
      throw Exception('Request timed out');
    }
  }

  Never _throwHttpError(int statusCode, String raw, String path) {
    try {
      final decoded = jsonDecode(raw);
      if (decoded is Map<String, dynamic>) {
        final msg = decoded['message'] as String?;
        if (msg != null && msg.isNotEmpty) {
          throw Exception(msg);
        }
      }
    } on Exception {
      rethrow;
    } catch (_) {}
    throw Exception('Request failed ($statusCode): $path');
  }
}
