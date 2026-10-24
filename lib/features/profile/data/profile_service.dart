import 'dart:convert';

import 'package:attendance/features/profile/data/profile_models.dart';
import 'package:attendance/services/api_client.dart';
import 'package:attendance/services/local_storage_service.dart';
import 'package:attendance/services/storage_keys.dart';

class ProfileService {
  ProfileService({ApiClient? apiClient, LocalStorageService? storage})
    : _api = apiClient ?? ApiClient(),
      _storage = storage ?? LocalStorageService.instance;

  final ApiClient _api;
  final LocalStorageService _storage;

  Future<void> _persistAuthUser(UserProfile profile) async {
    await _storage.setString(StorageKeys.authUser, jsonEncode(profile.toAuthUserJson()));
  }

  Future<UserProfile> fetchProfile() async {
    final decoded = await _api.getJson('/api/v1/me');
    final data = decoded['data'];
    if (data is! Map<String, dynamic>) {
      throw Exception('Invalid response');
    }
    final profile = UserProfile.fromJson(data);
    await _persistAuthUser(profile);
    return profile;
  }

  Future<UserProfile> updateProfile({required String name, required String email}) async {
    final decoded = await _api.postJson('/api/v1/profile/update', body: {'name': name, 'email': email});
    final data = decoded['data'];
    if (data is Map<String, dynamic>) {
      final profile = UserProfile.fromJson(data);
      await _persistAuthUser(profile);
      return profile;
    }
    return fetchProfile();
  }

  Future<void> changePassword({
    required String currentPassword,
    required String password,
    required String passwordConfirmation,
  }) async {
    await _api.postJson(
      '/api/v1/profile/password',
      body: {'current_password': currentPassword, 'password': password, 'password_confirmation': passwordConfirmation},
    );
  }

  Future<UserProfile> uploadAvatar({required String filePath, required String filename}) async {
    final lower = filename.toLowerCase();
    if (!lower.endsWith('.jpg') && !lower.endsWith('.jpeg') && !lower.endsWith('.png') && !lower.endsWith('.webp')) {
      throw Exception('Use JPG, PNG, or WebP (max 5 MB)');
    }

    final decoded = await _api.postMultipartFile(
      '/api/v1/profile/avatar',
      fileField: 'avatar',
      filePath: filePath,
      filename: filename,
    );
    final data = decoded['data'];
    if (data is Map<String, dynamic>) {
      final profile = UserProfile.fromJson(data);
      await _persistAuthUser(profile);
      return profile;
    }
    return fetchProfile();
  }
}
