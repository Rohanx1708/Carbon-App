import 'dart:convert';

import 'package:attendance/features/client/data/client_models.dart';
import 'package:attendance/services/api_client.dart';
import 'package:attendance/services/local_storage_service.dart';
import 'package:attendance/services/storage_keys.dart';
import 'package:attendance/core/cache/cache_stamp.dart';

export 'client_models.dart';

class ClientService {
  ClientService({ApiClient? apiClient, LocalStorageService? storage})
    : _api = apiClient ?? ApiClient(),
      _storage = storage ?? LocalStorageService.instance;

  final ApiClient _api;
  final LocalStorageService _storage;

  Future<void> _saveLocal(List<Client> list) async {
    final raw = list.map((e) => jsonEncode(e.toJson())).toList();
    await _storage.setStringList(StorageKeys.clients, raw);
    await _storage.setInt(StorageKeys.clientsCacheUpdatedAt, DateTime.now().millisecondsSinceEpoch);
  }

  Future<DateTime?> readLocalUpdatedAt() => CacheStamp.read(_storage, StorageKeys.clientsCacheUpdatedAt);

  Future<List<Client>> readLocal() async {
    final raw = await _storage.getStringList(StorageKeys.clients) ?? <String>[];
    return raw.map((e) => Client.fromJson(jsonDecode(e) as Map<String, dynamic>)).toList()
      ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
  }

  Future<List<Client>> fetchAllRemote() async {
    final decoded = await _api.getJson('/api/v1/clients');
    final data = decoded['data'];
    if (data is! List) throw Exception('Invalid response');

    final out = <Client>[];
    for (final item in data) {
      if (item is Map<String, dynamic>) out.add(Client.fromApiMap(item));
    }
    out.sort((a, b) => b.createdAt.compareTo(a.createdAt));
    await _saveLocal(out);
    return out;
  }

  Future<List<Client>> all() async {
    try {
      return await fetchAllRemote();
    } catch (_) {
      return readLocal();
    }
  }

  Future<ClientDetail> fetchDetails(int clientId) async {
    final decoded = await _api.getJson('/api/v1/clients/$clientId');
    final data = decoded['data'];
    if (data is! Map<String, dynamic>) throw Exception('Invalid response');
    return ClientDetail.fromApiMap(data);
  }

  Future<Client> create(Client client) async {
    final decoded = await _api.postJson('/api/v1/clients', body: client.toCreatePayload());
    final data = decoded['data'];
    if (data is Map<String, dynamic>) return Client.fromApiMap(data);
    return client;
  }

  Future<void> update({required int clientId, required Client client}) async {
    await _api.postJson('/api/v1/clients/$clientId/update', body: client.toUpdatePayload());
  }

  Future<void> deleteRemote(int clientId) async {
    await _api.postJson('/api/v1/clients/$clientId/delete');
  }

  Future<List<ClientDocument>> fetchDocuments(int clientId) async {
    final decoded = await _api.getJson('/api/v1/clients/$clientId/documents');
    final data = decoded['data'];
    if (data is! List) return [];
    return data.whereType<Map>().map((e) => ClientDocument.fromJson(e.cast<String, dynamic>())).toList();
  }

  Future<void> uploadDocument({
    required int clientId,
    required String filePath,
    required String filename,
    required String title,
  }) async {
    await _api.postMultipartFile(
      '/api/v1/clients/$clientId/documents',
      fileField: 'file',
      filePath: filePath,
      filename: filename,
      fields: {'title': title},
      maxFileBytes: 10 * 1024 * 1024,
    );
  }

  Future<void> deleteDocument({required int clientId, required int documentId}) async {
    await _api.postJson('/api/v1/clients/$clientId/documents/$documentId/delete');
  }
}
