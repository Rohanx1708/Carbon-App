import 'dart:convert';
import 'dart:io';

import 'package:shared_preferences/shared_preferences.dart';

import 'package:attendance/services/app_config.dart';

class AuthService {
  static const String _tokenKey = 'auth_token_v1';
  static const String _tokenTypeKey = 'auth_token_type_v1';
  static const String _userKey = 'auth_user_v1';

  Future<String?> getToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_tokenKey);
  }

  Future<String?> getTokenType() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_tokenTypeKey);
  }

  Future<Map<String, dynamic>?> getUser() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_userKey);
    if (raw == null) return null;
    try {
      return jsonDecode(raw) as Map<String, dynamic>;
    } catch (_) {
      return null;
    }
  }

  Future<bool> isLoggedIn() async {
    final token = await getToken();
    return token != null && token.trim().isNotEmpty;
  }

  Future<void> logout() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString(_tokenKey);
    final tokenType = prefs.getString(_tokenTypeKey) ?? 'Bearer';

    final baseUrl = AppConfig.baseUrl.trim();
    if (baseUrl.isNotEmpty && token != null && token.trim().isNotEmpty) {
      final uri = Uri.parse(baseUrl).resolve('/api/v1/logout');
      final client = HttpClient();
      try {
        final req = await client.postUrl(uri);
        req.headers.set(HttpHeaders.contentTypeHeader, 'application/json');
        req.headers.set(HttpHeaders.acceptHeader, 'application/json');
        req.headers.set(HttpHeaders.authorizationHeader, '$tokenType $token');
        final res = await req.close();
        await res.drain();
      } catch (_) {
        // ignore logout network errors; always clear local session
      } finally {
        client.close(force: true);
      }
    }

    await prefs.remove(_tokenKey);
    await prefs.remove(_tokenTypeKey);
    await prefs.remove(_userKey);
  }

  Future<({Map<String, dynamic> user, String token, String tokenType})> login({
    required String email,
    required String password,
  }) async {
    final baseUrl = AppConfig.baseUrl.trim();
    if (baseUrl.isEmpty) {
      throw Exception('BASE_URL is not configured');
    }

    final uri = Uri.parse(baseUrl).resolve('/api/v1/login');
    final client = HttpClient();
    try {
      final req = await client.postUrl(uri);
      req.headers.set(HttpHeaders.contentTypeHeader, 'application/json');

      final payload = jsonEncode({
        'email': email,
        'password': password,
      });
      req.add(utf8.encode(payload));

      final res = await req.close();
      final raw = await res.transform(utf8.decoder).join();

      final decoded = jsonDecode(raw) as Map<String, dynamic>;

      if (res.statusCode < 200 || res.statusCode >= 300) {
        final msg = (decoded['message'] as String?) ?? 'Login failed';
        throw Exception(msg);
      }

      final data = decoded['data'] as Map<String, dynamic>?;
      if (data == null) {
        throw Exception('Invalid response');
      }

      final token = (data['token'] as String?) ?? '';
      final tokenType = (data['token_type'] as String?) ?? 'Bearer';
      final user = (data['user'] as Map?)?.cast<String, dynamic>() ?? <String, dynamic>{};

      if (token.trim().isEmpty) {
        throw Exception('Token missing in response');
      }

      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_tokenKey, token);
      await prefs.setString(_tokenTypeKey, tokenType);
      await prefs.setString(_userKey, jsonEncode(user));

      return (user: user, token: token, tokenType: tokenType);
    } on SocketException {
      throw Exception('Network error');
    } finally {
      client.close(force: true);
    }
  }
}
