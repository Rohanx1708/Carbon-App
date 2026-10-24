import 'dart:convert';
import 'package:attendance/features/attendance/data/office_geofence.dart';

import 'package:attendance/features/attendance/data/remote_attendance_models.dart';
import 'package:attendance/services/api_client.dart';
import 'package:attendance/services/local_storage_service.dart';
import 'package:attendance/services/storage_keys.dart';
import 'package:attendance/core/cache/cache_stamp.dart';

export 'remote_attendance_models.dart';

class RemoteAttendanceService {
  RemoteAttendanceService({ApiClient? apiClient, LocalStorageService? storage})
    : _api = apiClient ?? ApiClient(),
      _storage = storage ?? LocalStorageService.instance;

  final ApiClient _api;
  final LocalStorageService _storage;

  List<RemoteAttendanceRecord> _parseList(Object? data) {
    if (data is! List) throw Exception('Invalid response');
    return data
        .whereType<Map>()
        .map((e) => RemoteAttendanceRecord.fromJson(e.cast<String, dynamic>()))
        .where((r) => r.id > 0)
        .toList();
  }

  Future<void> _saveLocal(List<RemoteAttendanceRecord> list) async {
    final sorted = [...list]
      ..sort((a, b) {
        final d = b.attendanceDate.compareTo(a.attendanceDate);
        if (d != 0) return d;
        return b.createdAt.compareTo(a.createdAt);
      });
    final raw = sorted.map((e) => jsonEncode(e.toJson())).toList();
    await _storage.setStringList(StorageKeys.remoteAttendanceRecords, raw);
    await _storage.setInt(StorageKeys.remoteAttendanceRecordsCacheUpdatedAt, DateTime.now().millisecondsSinceEpoch);
  }

  Future<DateTime?> readLocalUpdatedAt() => CacheStamp.read(_storage, StorageKeys.remoteAttendanceRecordsCacheUpdatedAt);

  Future<List<RemoteAttendanceRecord>> readLocal() async {
    final raw = await _storage.getStringList(StorageKeys.remoteAttendanceRecords) ?? <String>[];
    return raw
        .map((e) => RemoteAttendanceRecord.fromJson(jsonDecode(e) as Map<String, dynamic>))
        .where((r) => r.id > 0)
        .toList()
      ..sort((a, b) => b.attendanceDate.compareTo(a.attendanceDate));
  }

  Future<List<RemoteAttendanceRecord>> fetchAllRemote() async {
    final decoded = await _api.getJson('/api/v1/attendance');
    final list = _parseList(decoded['data']);
    await _saveLocal(list);
    return list;
  }

  Future<RemoteAttendanceRecord> fetchDetail(int attendanceId) async {
    final decoded = await _api.getJson('/api/v1/attendance/$attendanceId');
    final data = decoded['data'];
    if (data is! Map<String, dynamic>) throw Exception('Invalid response');
    return RemoteAttendanceRecord.fromJson(data);
  }

  Future<void> checkIn() async {
    final pos = await OfficeGeofence.verify(action: 'check in');
    await _api.postJson('/api/v1/attendance/check-in', body: {'latitude': pos.latitude, 'longitude': pos.longitude});
    await fetchAllRemote();
  }

  Future<void> checkOut() async {
    final pos = await OfficeGeofence.verify(action: 'check out');
    await _api.postJson('/api/v1/attendance/check-out', body: {'latitude': pos.latitude, 'longitude': pos.longitude});
    await fetchAllRemote();
  }

  Future<void> markHoliday({required String date, required String notes}) async {
    await _api.postJson('/api/v1/attendance/holiday', body: {'date': date, 'notes': notes});
    await fetchAllRemote();
  }

  Future<void> markAttendance({
    required int employeeId,
    required String attendanceDate,
    required String status,
    String? checkIn,
    String? checkOut,
  }) async {
    final body = <String, dynamic>{'employee_id': employeeId, 'attendance_date': attendanceDate, 'status': status};
    if (checkIn != null && checkIn.isNotEmpty) body['check_in'] = checkIn;
    if (checkOut != null && checkOut.isNotEmpty) body['check_out'] = checkOut;
    await _api.postJson('/api/v1/attendance', body: body);
    await fetchAllRemote();
  }
}
