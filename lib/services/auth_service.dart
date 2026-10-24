import 'dart:convert';

import 'package:attendance/services/api_client.dart';
import 'package:attendance/services/local_storage_service.dart';
import 'package:attendance/services/storage_keys.dart';

class AuthService {
  AuthService({ApiClient? apiClient, LocalStorageService? storage})
    : _api = apiClient ?? ApiClient(),
      _storage = storage ?? LocalStorageService.instance;

  final ApiClient _api;
  final LocalStorageService _storage;

  Future<String?> getToken() => _storage.getString(StorageKeys.authToken);

  Future<String?> getTokenType() => _storage.getString(StorageKeys.authTokenType);

  Future<Map<String, dynamic>?> getUser() async {
    final raw = await _storage.getString(StorageKeys.authUser);
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
    final token = await getToken();

    if (token != null && token.trim().isNotEmpty) {
      try {
        await _api.postJson('/api/v1/logout', authenticated: true);
      } catch (_) {
        // ignore logout network errors; always clear local session
      }
    }

    await _storage.remove(StorageKeys.authToken);
    await _storage.remove(StorageKeys.authTokenType);
    await _storage.remove(StorageKeys.authUser);
  }

  Future<({Map<String, dynamic> user, String token, String tokenType})> login({
    required String email,
    required String password,
  }) async {
    final decoded = await _api.postJson(
      '/api/v1/login',
      body: {'email': email, 'password': password},
      authenticated: false,
    );

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

    await _storage.setString(StorageKeys.authToken, token);
    await _storage.setString(StorageKeys.authTokenType, tokenType);
    await _storage.setString(StorageKeys.authUser, jsonEncode(user));

    return (user: user, token: token, tokenType: tokenType);
  }
}
