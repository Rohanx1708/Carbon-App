import 'dart:convert';

import 'package:attendance/core/cache/cache_stamp.dart';
import 'package:attendance/features/lead/data/lead_models.dart';
import 'package:attendance/services/api_client.dart';
import 'package:attendance/services/local_storage_service.dart';
import 'package:attendance/services/storage_keys.dart';

export 'lead_models.dart';

class LeadService {
  LeadService({ApiClient? apiClient, LocalStorageService? storage})
    : _api = apiClient ?? ApiClient(),
      _storage = storage ?? LocalStorageService.instance;

  final ApiClient _api;
  final LocalStorageService _storage;

  Map<String, String> _queryParams(LeadListQuery query) {
    final qp = <String, String>{};
    final status = (query.status ?? '').trim().toLowerCase();
    final stage = (query.stage ?? '').trim().toLowerCase();
    final source = (query.source ?? '').trim().toLowerCase();
    final search = (query.search ?? '').trim();
    if (status.isNotEmpty) qp['status'] = status;
    if (stage.isNotEmpty) qp['stage'] = stage;
    if (source.isNotEmpty) qp['source'] = source;
    if (search.isNotEmpty) qp['search'] = search;
    return qp;
  }

  Future<void> _save(List<Lead> list) async {
    final raw = list.map((e) => jsonEncode(e.toJson())).toList();
    await _storage.setStringList(StorageKeys.leads, raw);
    await _storage.setInt(StorageKeys.leadsCacheUpdatedAt, DateTime.now().millisecondsSinceEpoch);
  }

  Future<List<Lead>> _allLocal() async {
    final raw = await _storage.getStringList(StorageKeys.leads) ?? <String>[];
    final list = raw.map((e) => Lead.fromJson(jsonDecode(e) as Map<String, dynamic>)).toList();
    list.sort((a, b) => b.createdAt.compareTo(a.createdAt));
    return list;
  }

  Future<List<Lead>> fetchAllRemote({LeadListQuery query = const LeadListQuery()}) async {
    final qp = _queryParams(query);
    final decoded = await _api.getJson('/api/v1/leads', queryParameters: qp.isEmpty ? null : qp);
    final data = decoded['data'];
    if (data is! List) {
      throw Exception('Invalid response');
    }

    final out = <Lead>[];
    for (final item in data) {
      if (item is! Map) continue;
      out.add(Lead.fromApiMap(item.cast<String, dynamic>()));
    }
    out.sort((a, b) => b.createdAt.compareTo(a.createdAt));
    await _save(out);
    return out;
  }

  Future<LeadDetail> fetchDetails(int leadId) async {
    final decoded = await _api.getJson('/api/v1/leads/$leadId');
    final data = decoded['data'];
    if (data is! Map<String, dynamic>) {
      throw Exception('Invalid response');
    }
    return LeadDetail.fromApiMap(data);
  }

  Future<Lead> createRemote(Lead lead) async {
    final decoded = await _api.postJson('/api/v1/leads', body: lead.toCreatePayload());
    final data = decoded['data'];
    if (data is Map<String, dynamic>) {
      return Lead.fromApiMap(data);
    }
    return lead;
  }

  Future<Lead> updateRemote({required int leadId, required Lead lead}) async {
    await _api.postJson('/api/v1/leads/$leadId/update', body: lead.toUpdatePayload());
    return fetchDetails(leadId).then((d) => d.lead);
  }

  Future<void> deleteRemote(int leadId) async {
    await _api.postJson('/api/v1/leads/$leadId/delete');
  }

  Future<List<LeadComment>> fetchComments(int leadId) async {
    final decoded = await _api.getJson('/api/v1/leads/$leadId/comments');
    return _parseList(decoded['data'], LeadComment.fromJson);
  }

  Future<LeadComment> addComment({required int leadId, required String comment, String type = 'remark'}) async {
    final decoded = await _api.postJson('/api/v1/leads/$leadId/comments', body: {'comment': comment, 'type': type});
    final data = decoded['data'];
    if (data is Map<String, dynamic>) {
      return LeadComment.fromJson(data);
    }
    throw Exception('Invalid response');
  }

  Future<void> changeStatus({required int leadId, required String leadStatus, String? remark}) async {
    await _api.postJson(
      '/api/v1/leads/$leadId/status',
      body: {
        'lead_status': leadStatus.toLowerCase(),
        if (remark != null && remark.trim().isNotEmpty) 'remark': remark.trim(),
      },
    );
  }

  Future<void> changeStage({required int leadId, required String stage, String? remark}) async {
    await _api.postJson(
      '/api/v1/leads/$leadId/stage',
      body: {'stage': stage.toLowerCase(), if (remark != null && remark.trim().isNotEmpty) 'remark': remark.trim()},
    );
  }

  Future<List<LeadDocument>> fetchDocuments(int leadId) async {
    final decoded = await _api.getJson('/api/v1/leads/$leadId/documents');
    return _parseList(decoded['data'], LeadDocument.fromJson);
  }

  Future<void> uploadDocument({
    required int leadId,
    required String filePath,
    required String filename,
    required String title,
  }) async {
    await _api.postMultipartFile(
      '/api/v1/leads/$leadId/documents',
      fileField: 'file',
      filePath: filePath,
      filename: filename,
      fields: {'title': title},
      maxFileBytes: 10 * 1024 * 1024,
    );
  }

  Future<void> deleteDocument({required int leadId, required int documentId}) async {
    await _api.postJson('/api/v1/leads/$leadId/documents/$documentId/delete');
  }

  Future<List<LeadActionItem>> fetchActions(int leadId) async {
    final decoded = await _api.getJson('/api/v1/leads/$leadId/actions');
    return _parseList(decoded['data'], LeadActionItem.fromJson);
  }

  Future<void> addAction({
    required int leadId,
    required String actionType,
    required String description,
    required String actionDate,
    required String actionTime,
  }) async {
    await _api.postJson(
      '/api/v1/leads/$leadId/actions',
      body: {
        'action_type': actionType,
        'description': description,
        'action_date': actionDate,
        'action_time': actionTime,
      },
    );
  }

  Future<void> completeAction({required int leadId, required int actionId, required String mom, String? remark}) async {
    await _api.postJson(
      '/api/v1/leads/$leadId/actions/$actionId/complete',
      body: {'mom': mom, if (remark != null && remark.trim().isNotEmpty) 'remark': remark.trim()},
    );
  }

  Future<void> scheduleMeeting({
    required int leadId,
    required String title,
    required String date,
    required String time,
    required String endTime,
    required String location,
    required int organizerId,
  }) async {
    await _api.postJson(
      '/api/v1/leads/$leadId/meetings',
      body: {
        'title': title,
        'date': date,
        'time': time,
        'end_time': endTime,
        'location': location,
        'organizer_id': organizerId,
      },
    );
  }

  List<T> _parseList<T>(Object? data, T Function(Map<String, dynamic>) fromJson) {
    if (data is! List) return <T>[];
    final out = <T>[];
    for (final item in data) {
      if (item is Map<String, dynamic>) {
        out.add(fromJson(item));
      } else if (item is Map) {
        out.add(fromJson(item.cast<String, dynamic>()));
      }
    }
    return out;
  }

  Future<DateTime?> readLocalUpdatedAt() => CacheStamp.read(_storage, StorageKeys.leadsCacheUpdatedAt);

  Future<List<Lead>> readLocal() => _allLocal();

  List<Lead> filterLocalList(List<Lead> list, {LeadListQuery query = const LeadListQuery()}) {
    final normalizedStatus = (query.status ?? '').trim().toLowerCase();
    final normalizedStage = (query.stage ?? '').trim().toLowerCase();
    final normalizedSource = (query.source ?? '').trim().toLowerCase();
    final normalizedSearch = (query.search ?? '').trim().toLowerCase();
    return list.where((l) {
      if (normalizedStatus.isNotEmpty && l.leadStatus.toLowerCase() != normalizedStatus) {
        return false;
      }
      if (normalizedStage.isNotEmpty && (l.stage ?? '').toLowerCase() != normalizedStage) {
        return false;
      }
      if (normalizedSource.isNotEmpty && (l.source ?? '').toLowerCase() != normalizedSource) {
        return false;
      }
      if (normalizedSearch.isEmpty) return true;
      return l.companyName.toLowerCase().contains(normalizedSearch) ||
          l.companyEmail.toLowerCase().contains(normalizedSearch) ||
          l.companyPhone.toLowerCase().contains(normalizedSearch) ||
          l.industry.toLowerCase().contains(normalizedSearch) ||
          l.leadStatus.toLowerCase().contains(normalizedSearch) ||
          (l.leadCode ?? '').toLowerCase().contains(normalizedSearch);
    }).toList();
  }

  Future<List<Lead>> all({LeadListQuery query = const LeadListQuery()}) async {
    try {
      return await fetchAllRemote(query: query);
    } catch (_) {
      return filterLocalList(await _allLocal(), query: query);
    }
  }

  Future<void> add(Lead lead) async {
    await createRemote(lead);
  }

  Future<void> updateAt(int index, Lead lead) async {
    final list = await all();
    if (index < 0 || index >= list.length) return;
    list[index] = lead;
    await _save(list);
  }

  Future<void> deleteAt(int index) async {
    final list = await all();
    if (index < 0 || index >= list.length) return;
    list.removeAt(index);
    await _save(list);
  }
}
