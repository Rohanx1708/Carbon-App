import 'package:flutter/foundation.dart';

import 'package:attendance/features/leave/data/leave_service.dart';

class LeaveProvider extends ChangeNotifier {
  LeaveProvider({LeaveService? service}) : _service = service ?? LeaveService();

  final LeaveService _service;

  List<LeaveRequest> _leaves = <LeaveRequest>[];
  List<LeaveRequest> get leaves => _leaves;

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
    _loading = true;
    _error = null;
    notifyListeners();
    try {
      final list = await _service.all();
      if (seq != _loadSeq) return;
      _leaves = list;
      _hasLoaded = true;
    } catch (e) {
      if (seq == _loadSeq) {
        _error = e;
      }
    }
    if (seq == _loadSeq) {
      _loading = false;
      notifyListeners();
    }
  }

  Future<bool> add(LeaveRequest req) async {
    _loading = true;
    _error = null;
    notifyListeners();
    try {
      await _service.add(req);
      await refresh();
      return true;
    } catch (e) {
      _error = e;
      _loading = false;
      notifyListeners();
      return false;
    }
  }

  Future<void> updateAt(int index, LeaveRequest req) async {
    await _service.updateAt(index, req);
    await refresh();
  }

  Future<void> deleteAt(int index) async {
    await _service.deleteAt(index);
    await refresh();
  }

  void clearSession() {
    _loadSeq++;
    _leaves = <LeaveRequest>[];
    _hasLoaded = false;
    _error = null;
    _loading = false;
    notifyListeners();
  }
}
