import 'dart:convert';

import 'package:attendance/features/project/data/project_models.dart';
import 'package:attendance/services/api_client.dart';
import 'package:attendance/services/local_storage_service.dart';
import 'package:attendance/services/storage_keys.dart';
import 'package:attendance/core/cache/cache_stamp.dart';

export 'project_models.dart';

class ProjectService {
  ProjectService({ApiClient? apiClient, LocalStorageService? storage})
    : _api = apiClient ?? ApiClient(),
      _storage = storage ?? LocalStorageService.instance;

  final ApiClient _api;
  final LocalStorageService _storage;

  Future<void> _saveLocal(List<Project> list) async {
    final raw = list.map((e) => jsonEncode(e.toJson())).toList();
    await _storage.setStringList(StorageKeys.projects, raw);
    await _storage.setInt(StorageKeys.projectsCacheUpdatedAt, DateTime.now().millisecondsSinceEpoch);
  }

  Future<DateTime?> readLocalUpdatedAt() => CacheStamp.read(_storage, StorageKeys.projectsCacheUpdatedAt);

  Future<List<Project>> readLocal() async {
    final raw = await _storage.getStringList(StorageKeys.projects) ?? <String>[];
    return raw.map((e) => Project.fromJson(jsonDecode(e) as Map<String, dynamic>)).toList()
      ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
  }

  Future<List<Project>> fetchAllRemote() async {
    final decoded = await _api.getJson('/api/v1/projects');
    final data = decoded['data'];
    if (data is! List) throw Exception('Invalid response');

    final out = <Project>[];
    for (final item in data) {
      if (item is Map<String, dynamic>) out.add(Project.fromApiMap(item));
    }
    out.sort((a, b) => b.createdAt.compareTo(a.createdAt));
    await _saveLocal(out);
    return out;
  }

  Future<List<Project>> all() async {
    try {
      return await fetchAllRemote();
    } catch (_) {
      return readLocal();
    }
  }

  Future<ProjectDetail> fetchDetails(int projectId) async {
    final decoded = await _api.getJson('/api/v1/projects/$projectId');
    final data = decoded['data'];
    if (data is! Map<String, dynamic>) throw Exception('Invalid response');
    return ProjectDetail.fromApiMap(data);
  }

  Future<Project> create(ProjectCreateRequest request) async {
    final decoded = await _api.postJson('/api/v1/projects', body: request.toJson());
    final data = decoded['data'];
    if (data is Map<String, dynamic>) return Project.fromApiMap(data);
    throw Exception('Invalid response');
  }

  Future<void> update({required int projectId, required Map<String, dynamic> body}) async {
    await _api.postJson('/api/v1/projects/$projectId/update', body: body);
  }

  Future<void> deleteRemote(int projectId) async {
    await _api.postJson('/api/v1/projects/$projectId/delete');
  }

  Future<List<ProjectDocument>> fetchDocuments(int projectId) async {
    final decoded = await _api.getJson('/api/v1/projects/$projectId/documents');
    final data = decoded['data'];
    if (data is! List) return [];
    return data.whereType<Map>().map((e) => ProjectDocument.fromJson(e.cast<String, dynamic>())).toList();
  }

  Future<void> uploadDocument({
    required int projectId,
    required String filePath,
    required String filename,
    required String title,
  }) async {
    await _api.postMultipartFile(
      '/api/v1/projects/$projectId/documents',
      fileField: 'file',
      filePath: filePath,
      filename: filename,
      fields: {'title': title},
      maxFileBytes: 10 * 1024 * 1024,
    );
  }

  Future<void> deleteDocument({required int projectId, required int documentId}) async {
    await _api.postJson('/api/v1/projects/$projectId/documents/$documentId/delete');
  }
}
