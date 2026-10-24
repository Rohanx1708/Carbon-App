import 'package:flutter/foundation.dart';

import 'package:attendance/features/attendance/data/attendance_service.dart';

class AttendanceProvider extends ChangeNotifier {
  AttendanceProvider({AttendanceService? service}) : _service = service ?? AttendanceService();

  final AttendanceService _service;

  List<AttendanceRecord> _records = <AttendanceRecord>[];
  List<AttendanceRecord> get records => _records;

  bool _loading = false;
  bool get loading => _loading;

  Object? _error;
  Object? get error => _error;

  bool _hasLoaded = false;
  bool get hasLoaded => _hasLoaded;

  int _loadSeq = 0;

  Future<void> loadIfNeeded() async {
    if (_hasLoaded) return;
    await refresh();
  }

  Future<void> refresh() async {
    final seq = ++_loadSeq;
    try {
      _error = null;
      final list = await _service.records();
      if (seq != _loadSeq) return;
      _records = list;
      _hasLoaded = true;
      notifyListeners();
    } catch (e) {
      if (seq != _loadSeq) return;
      _error = e;
      notifyListeners();
    }
  }

  Future<AttendanceRecord?> punch({required String action}) async {
    _loading = true;
    _error = null;
    notifyListeners();
    try {
      final record = await _service.punch(action: action);
      _records = <AttendanceRecord>[record, ..._records];
      _hasLoaded = true;
      return record;
    } catch (e) {
      _error = e;
      return null;
    } finally {
      _loading = false;
      notifyListeners();
    }
  }

  Future<void> clearAll() async {
    await _service.clearAll();
    _records = <AttendanceRecord>[];
    _hasLoaded = true;
    notifyListeners();
  }

  void clearSession() {
    _loadSeq++;
    _records = <AttendanceRecord>[];
    _hasLoaded = false;
    _error = null;
    _loading = false;
    notifyListeners();
  }
}
