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

  Future<void> load() async {
    _loading = true;
    _error = null;
    notifyListeners();
    try {
      _leaves = await _service.all();
    } catch (e) {
      _error = e;
    } finally {
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
      await load();
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
    await load();
  }

  Future<void> deleteAt(int index) async {
    await _service.deleteAt(index);
    await load();
  }
}
