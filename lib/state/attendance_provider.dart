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

  Future<void> load() async {
    try {
      _error = null;
      final list = await _service.records();
      _records = list;
      notifyListeners();
    } catch (e) {
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
    notifyListeners();
  }
}
