import 'dart:convert';

import 'package:attendance/features/leave_request/data/leave_request_models.dart';
import 'package:attendance/services/api_client.dart';
import 'package:attendance/services/local_storage_service.dart';
import 'package:attendance/services/storage_keys.dart';
import 'package:attendance/core/cache/cache_stamp.dart';

export 'leave_request_models.dart';

class LeaveRequestService {
  LeaveRequestService({ApiClient? apiClient, LocalStorageService? storage})
    : _api = apiClient ?? ApiClient(),
      _storage = storage ?? LocalStorageService.instance;

  final ApiClient _api;
  final LocalStorageService _storage;

  List<LeaveRequestItem> _parseList(Object? data) {
    if (data is! List) {
      throw Exception('Invalid response');
    }
    return data
        .whereType<Map>()
        .map((e) => LeaveRequestItem.fromJson(e.cast<String, dynamic>()))
        .where((r) => r.id > 0)
        .toList();
  }

  Future<void> _saveLocal(List<LeaveRequestItem> list) async {
    final sorted = [...list]..sort((a, b) => b.createdAt.compareTo(a.createdAt));
    final raw = sorted.map((e) => jsonEncode(e.toJson())).toList();
    await _storage.setStringList(StorageKeys.leaveApprovalRequests, raw);
    await _storage.setInt(StorageKeys.leaveApprovalRequestsCacheUpdatedAt, DateTime.now().millisecondsSinceEpoch);
  }

  Future<DateTime?> readLocalUpdatedAt() => CacheStamp.read(_storage, StorageKeys.leaveApprovalRequestsCacheUpdatedAt);

  Future<List<LeaveRequestItem>> readLocal() async {
    final raw = await _storage.getStringList(StorageKeys.leaveApprovalRequests) ?? <String>[];
    return raw
        .map((e) => LeaveRequestItem.fromJson(jsonDecode(e) as Map<String, dynamic>))
        .where((r) => r.id > 0)
        .toList()
      ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
  }

  Future<List<LeaveRequestItem>> fetchAllRemote() async {
    final decoded = await _api.getJson('/api/v1/leave-requests');
    final list = _parseList(decoded['data']);
    list.sort((a, b) => b.createdAt.compareTo(a.createdAt));
    await _saveLocal(list);
    return list;
  }

  Future<LeaveRequestItem> fetchDetail(int requestId) async {
    final decoded = await _api.getJson('/api/v1/leave-requests/$requestId');
    final data = decoded['data'];
    if (data is! Map<String, dynamic>) {
      throw Exception('Invalid response');
    }
    return LeaveRequestItem.fromJson(data);
  }

  Future<void> approve({required int requestId, required String reviewNote}) async {
    await _api.postJson('/api/v1/leave-requests/$requestId/approve', body: {'review_note': reviewNote});
    await fetchAllRemote();
  }

  Future<void> reject({required int requestId, required String reviewNote}) async {
    await _api.postJson('/api/v1/leave-requests/$requestId/reject', body: {'review_note': reviewNote});
    await fetchAllRemote();
  }

  Future<void> submit({required String startDate, required String endDate, required String reason}) async {
    await _api.postJson(
      '/api/v1/leave-requests',
      body: {'start_date': startDate, 'end_date': endDate, 'reason': reason},
    );
    await fetchAllRemote();
  }

  Future<void> cancel({required int requestId, required String cancelReason}) async {
    await _api.postJson('/api/v1/leave-requests/$requestId/cancel', body: {'cancel_reason': cancelReason});
    await fetchAllRemote();
  }

  Future<LeaveRequestPreview> preview({required String startDate, required String endDate}) async {
    final decoded = await _api.postJson(
      '/api/v1/leave-requests/preview',
      body: {'start_date': startDate, 'end_date': endDate},
    );
    final data = decoded['data'];
    if (data is Map<String, dynamic>) return LeaveRequestPreview.fromJson(data);
    if (decoded['paid_days'] != null || decoded['days'] != null) {
      return LeaveRequestPreview.fromJson(decoded);
    }
    throw Exception('Invalid response');
  }
}

class LeaveRequestPreview {
  const LeaveRequestPreview({
    required this.days,
    required this.paidDays,
    required this.unpaidDays,
    this.workingDays,
    this.holidays,
    this.weekOffs,
    this.balance,
  });

  final int days;
  final int paidDays;
  final int unpaidDays;
  final int? workingDays;
  final int? holidays;
  final int? weekOffs;
  final int? balance;

  static int _int(Object? v) => int.tryParse(v?.toString() ?? '') ?? 0;
  static int? _intOrNull(Object? v) => v == null ? null : int.tryParse(v.toString());

  factory LeaveRequestPreview.fromJson(Map<String, dynamic> j) {
    final paid = _int(j['paid_days']);
    final unpaid = _int(j['unpaid_days']);
    final days = _int(j['days'] ?? j['total_days']);
    return LeaveRequestPreview(
      days: days > 0 ? days : paid + unpaid,
      paidDays: paid,
      unpaidDays: unpaid,
      workingDays: _intOrNull(j['working_days']),
      holidays: _intOrNull(j['holidays'] ?? j['holiday_days']),
      weekOffs: _intOrNull(j['week_offs'] ?? j['week_off_days']),
      balance: _intOrNull(j['balance'] ?? j['remaining_balance'] ?? j['leave_balance']),
    );
  }
}
