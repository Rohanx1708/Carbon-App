import 'package:flutter/foundation.dart';

import 'package:attendance/core/cache/cache_policy.dart';
import 'package:attendance/core/cache/cache_stamp.dart';
import 'package:attendance/core/cache/hybrid_list_loader.dart';
import 'package:attendance/features/attendance/data/remote_attendance_service.dart';

class RemoteAttendanceProvider extends ChangeNotifier {
  RemoteAttendanceProvider({RemoteAttendanceService? service}) : _service = service ?? RemoteAttendanceService();

  final RemoteAttendanceService _service;

  List<RemoteAttendanceRecord> _records = <RemoteAttendanceRecord>[];
  List<RemoteAttendanceRecord> get records => _records;

  bool _loading = false;
  bool get loading => _loading;

  bool _refreshing = false;
  bool get refreshing => _refreshing;

  bool _acting = false;
  bool get acting => _acting;

  Object? _error;
  Object? get error => _error;

  bool _hasLoaded = false;
  bool get hasLoaded => _hasLoaded;

  DateTime? _loadedAt;
  int _loadSeq = 0;

  Future<void> loadIfNeeded() async {
    if (_hasLoaded && CacheStamp.isFresh(_loadedAt, CachePolicy.listTtl)) return;
    await refresh(force: false);
  }

  Future<void> refresh({bool force = true}) async {
    final seq = ++_loadSeq;
    _error = null;
    _loading = !_hasLoaded && _records.isEmpty;
    _refreshing = _records.isNotEmpty || _hasLoaded;
    notifyListeners();

    try {
      final results = await HybridListLoader.load(
        readLocal: _service.readLocal,
        fetchRemote: _service.fetchAllRemote,
        readUpdatedAt: _service.readLocalUpdatedAt,
        ttl: CachePolicy.listTtl,
        force: force,
        onStale: (stale) {
          if (seq != _loadSeq) return;
          _records = stale;
          _hasLoaded = true;
          _loading = false;
          _refreshing = true;
          _error = null;
          notifyListeners();
        },
      );
      if (seq != _loadSeq) return;
      _records = results;
      _hasLoaded = true;
      _loadedAt = DateTime.now();
      _error = null;
    } catch (e) {
      if (seq == _loadSeq && _records.isEmpty) _error = e;
    }
    if (seq == _loadSeq) {
      _loading = false;
      _refreshing = false;
      notifyListeners();
    }
  }

  Future<bool> _runAction(Future<void> Function() action) async {
    _acting = true;
    _error = null;
    notifyListeners();
    try {
      await action();
      await refresh();
      return true;
    } catch (e) {
      _error = e;
      notifyListeners();
      return false;
    } finally {
      _acting = false;
      notifyListeners();
    }
  }

  Future<bool> checkIn() => _runAction(_service.checkIn);

  Future<bool> checkOut() => _runAction(_service.checkOut);

  Future<bool> markHoliday({required String date, required String notes}) =>
      _runAction(() => _service.markHoliday(date: date, notes: notes));

  Future<bool> markAttendance({
    required int employeeId,
    required String attendanceDate,
    required String status,
    String? checkIn,
    String? checkOut,
  }) => _runAction(
    () => _service.markAttendance(
      employeeId: employeeId,
      attendanceDate: attendanceDate,
      status: status,
      checkIn: checkIn,
      checkOut: checkOut,
    ),
  );

  void clearSession() {
    _loadSeq++;
    _records = <RemoteAttendanceRecord>[];
    _hasLoaded = false;
    _loadedAt = null;
    _error = null;
    _loading = false;
    _refreshing = false;
    notifyListeners();
  }
}
