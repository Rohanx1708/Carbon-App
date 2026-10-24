import 'dart:convert';

import 'package:attendance/features/lead/data/lead_models.dart';
import 'package:attendance/features/task/data/task_models.dart';
import 'package:attendance/services/api_client.dart';
import 'package:attendance/services/local_storage_service.dart';
import 'package:attendance/services/storage_keys.dart';
import 'package:attendance/core/cache/cache_stamp.dart';

export 'task_models.dart';

class TaskService {
  TaskService({ApiClient? apiClient, LocalStorageService? storage})
    : _api = apiClient ?? ApiClient(),
      _storage = storage ?? LocalStorageService.instance;

  final ApiClient _api;
  final LocalStorageService _storage;

  List<TaskItem> _parseList(Object? data) {
    if (data is! List) throw Exception('Invalid response');
    return data
        .whereType<Map>()
        .map((e) => TaskItem.fromJson(e.cast<String, dynamic>()))
        .where((t) => t.id > 0)
        .toList();
  }

  Future<void> _saveLocal(List<TaskItem> list) async {
    final sorted = [...list]..sort((a, b) => b.updatedAt.compareTo(a.updatedAt));
    final raw = sorted.map((e) => jsonEncode(e.toJson())).toList();
    await _storage.setStringList(StorageKeys.tasks, raw);
    await _storage.setInt(StorageKeys.tasksCacheUpdatedAt, DateTime.now().millisecondsSinceEpoch);
  }

  Future<DateTime?> readLocalUpdatedAt() => CacheStamp.read(_storage, StorageKeys.tasksCacheUpdatedAt);

  Future<List<TaskItem>> readLocal() async {
    final raw = await _storage.getStringList(StorageKeys.tasks) ?? <String>[];
    return raw.map((e) => TaskItem.fromJson(jsonDecode(e) as Map<String, dynamic>)).where((t) => t.id > 0).toList()
      ..sort((a, b) => b.updatedAt.compareTo(a.updatedAt));
  }

  Future<List<TaskItem>> fetchAllRemote() async {
    final decoded = await _api.getJson('/api/v1/tasks');
    final list = _parseList(decoded['data']);
    await _saveLocal(list);
    return list;
  }

  Future<TaskDetail> fetchDetail(int taskId) async {
    final decoded = await _api.getJson('/api/v1/tasks/$taskId');
    final data = decoded['data'];
    if (data is! Map<String, dynamic>) throw Exception('Invalid response');
    return TaskDetail.fromJson(data);
  }

  Future<int?> create(TaskCreateInput input) async {
    final decoded = await _api.postJson('/api/v1/tasks', body: input.toJson());
    final data = decoded['data'];
    if (data is Map) {
      return int.tryParse((data['id'] ?? '').toString());
    }
    return int.tryParse((decoded['id'] ?? '').toString());
  }

  Future<void> update({required int taskId, required Map<String, dynamic> body}) async {
    await _api.postJson('/api/v1/tasks/$taskId/update', body: body);
  }

  Future<void> deleteRemote(int taskId) async {
    await _api.postJson('/api/v1/tasks/$taskId/delete');
  }

  Future<void> changeStatus({required int taskId, required String status, String? comment}) async {
    await _api.postJson(
      '/api/v1/tasks/$taskId/status',
      body: {'status': status, if (comment != null && comment.trim().isNotEmpty) 'comment': comment.trim()},
    );
  }

  Future<void> addComment({required int taskId, required String comment}) async {
    await _api.postJson('/api/v1/tasks/$taskId/comments', body: {'comment': comment});
  }

  Future<List<LeadDocument>> fetchDocuments(int taskId) async {
    final decoded = await _api.getJson('/api/v1/tasks/$taskId/documents');
    final data = decoded['data'];
    if (data is! List) return [];
    return data.whereType<Map>().map((e) => LeadDocument.fromJson(e.cast<String, dynamic>())).toList();
  }

  Future<void> uploadDocument({
    required int taskId,
    required String filePath,
    required String filename,
    required String title,
  }) async {
    await _api.postMultipartFile(
      '/api/v1/tasks/$taskId/documents',
      fileField: 'file',
      filePath: filePath,
      filename: filename,
      fields: {'title': title},
      maxFileBytes: 10 * 1024 * 1024,
    );
  }

  Future<void> deleteDocument({required int taskId, required int documentId}) async {
    await _api.postJson('/api/v1/tasks/$taskId/documents/$documentId/delete');
  }
}
