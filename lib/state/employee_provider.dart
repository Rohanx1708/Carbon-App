import 'package:flutter/foundation.dart';

import 'package:attendance/core/cache/cache_policy.dart';
import 'package:attendance/core/cache/cache_stamp.dart';
import 'package:attendance/core/cache/hybrid_list_loader.dart';
import 'package:attendance/features/employee/data/employee_service.dart';
import 'package:attendance/services/directory_cache_service.dart';

class EmployeeProvider extends ChangeNotifier {
  EmployeeProvider({EmployeeService? service}) : _service = service ?? EmployeeService();

  final EmployeeService _service;

  List<Employee> _employees = <Employee>[];
  List<Employee> get employees => _employees;

  bool _loading = false;
  bool get loading => _loading;

  bool _refreshing = false;
  bool get refreshing => _refreshing;

  Object? _error;
  Object? get error => _error;

  bool _hasLoaded = false;
  bool get hasLoaded => _hasLoaded;

  DateTime? _loadedAt;
  int _loadSeq = 0;

  Future<void> loadIfNeeded() async {
    if (_hasLoaded && CacheStamp.isFresh(_loadedAt, CachePolicy.listTtl)) return;
    await load(force: false);
  }

  Future<void> load({bool force = true}) async {
    final seq = ++_loadSeq;
    _error = null;
    _loading = !_hasLoaded && _employees.isEmpty;
    _refreshing = _employees.isNotEmpty || _hasLoaded;
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
          _employees = stale;
          _hasLoaded = true;
          _loading = false;
          _refreshing = true;
          notifyListeners();
        },
      );
      if (seq != _loadSeq) return;
      _employees = results;
      _hasLoaded = true;
      _loadedAt = DateTime.now();
      _error = null;
    } catch (e) {
      if (seq == _loadSeq && _employees.isEmpty) {
        _error = e;
      }
    }
    if (seq == _loadSeq) {
      _loading = false;
      _refreshing = false;
      notifyListeners();
    }
  }

  Future<void> refresh() async {
    _hasLoaded = false;
    await load();
  }

  Future<bool> create(EmployeeCreateInput input) async {
    _error = null;
    notifyListeners();
    try {
      await _service.createEmployee(input);
      await DirectoryCacheService.instance.employees(force: true);
      await refresh();
      return true;
    } catch (e) {
      _error = e;
      notifyListeners();
      return false;
    }
  }

  Future<bool> updateEmployee(int id, Map<String, dynamic> body) async {
    _error = null;
    notifyListeners();
    try {
      await _service.updateEmployee(id, body);
      await DirectoryCacheService.instance.employees(force: true);
      await refresh();
      return true;
    } catch (e) {
      _error = e;
      notifyListeners();
      return false;
    }
  }

  Future<bool> deleteEmployee(int id) async {
    _error = null;
    notifyListeners();
    try {
      await _service.deleteEmployee(id);
      await DirectoryCacheService.instance.employees(force: true);
      await refresh();
      return true;
    } catch (e) {
      _error = e;
      notifyListeners();
      return false;
    }
  }

  void clearSession() {
    _loadSeq++;
    _employees = <Employee>[];
    _hasLoaded = false;
    _loadedAt = null;
    _error = null;
    _loading = false;
    _refreshing = false;
    notifyListeners();
  }
}
