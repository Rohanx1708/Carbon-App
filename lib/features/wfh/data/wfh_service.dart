import 'dart:convert';

import 'package:attendance/features/wfh/data/wfh_models.dart';
import 'package:attendance/services/api_client.dart';
import 'package:attendance/services/local_storage_service.dart';
import 'package:attendance/services/storage_keys.dart';
import 'package:attendance/core/cache/cache_stamp.dart';

class WfhService {
  WfhService({ApiClient? apiClient, LocalStorageService? storage})
    : _api = apiClient ?? ApiClient(),
      _storage = storage ?? LocalStorageService.instance;

  final ApiClient _api;
  final LocalStorageService _storage;

  List<WfhRequest> _parseList(Object? data) {
    if (data is! List) {
      throw Exception('Invalid response');
    }
    return data
        .whereType<Map>()
        .map((e) => WfhRequest.fromJson(e.cast<String, dynamic>()))
        .where((r) => r.id > 0)
        .toList();
  }

  Future<void> _saveLocal(List<WfhRequest> list) async {
    final sorted = [...list]..sort((a, b) => b.createdAt.compareTo(a.createdAt));
    final raw = sorted.map((e) => jsonEncode(e.toJson())).toList();
    await _storage.setStringList(StorageKeys.wfhRequests, raw);
    await _storage.setInt(StorageKeys.wfhRequestsCacheUpdatedAt, DateTime.now().millisecondsSinceEpoch);
  }

  Future<DateTime?> readLocalUpdatedAt() => CacheStamp.read(_storage, StorageKeys.wfhRequestsCacheUpdatedAt);

  Future<List<WfhRequest>> readLocal() async {
    final raw = await _storage.getStringList(StorageKeys.wfhRequests) ?? <String>[];
    return raw.map((e) => WfhRequest.fromJson(jsonDecode(e) as Map<String, dynamic>)).where((r) => r.id > 0).toList()
      ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
  }

  Future<List<WfhRequest>> fetchAllRemote() async {
    final decoded = await _api.getJson('/api/v1/wfh-requests');
    final list = _parseList(decoded['data']);
    list.sort((a, b) => b.createdAt.compareTo(a.createdAt));
    await _saveLocal(list);
    return list;
  }

  Future<WfhRequest> fetchDetail(int requestId) async {
    final decoded = await _api.getJson('/api/v1/wfh-requests/$requestId');
    final data = decoded['data'];
    if (data is! Map<String, dynamic>) {
      throw Exception('Invalid response');
    }
    return WfhRequest.fromJson(data);
  }

  Future<void> approve({required int requestId, required String reviewNote}) async {
    await _api.postJson('/api/v1/wfh-requests/$requestId/approve', body: {'review_note': reviewNote});
    await fetchAllRemote();
  }

  Future<void> reject({required int requestId, required String reviewNote}) async {
    await _api.postJson('/api/v1/wfh-requests/$requestId/reject', body: {'review_note': reviewNote});
    await fetchAllRemote();
  }

  Future<void> submit({required String wfhDate, required String reason}) async {
    await _api.postJson('/api/v1/wfh-requests', body: {'wfh_date': wfhDate, 'reason': reason});
    await fetchAllRemote();
  }
}
