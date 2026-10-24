import 'package:flutter/foundation.dart';

import 'package:attendance/core/cache/cache_policy.dart';
import 'package:attendance/core/cache/cache_stamp.dart';
import 'package:attendance/features/dashboard/data/dashboard_models.dart';
import 'package:attendance/features/dashboard/data/dashboard_service.dart';

class DashboardProvider extends ChangeNotifier {
  DashboardProvider({DashboardService? service}) : _service = service ?? DashboardService();

  final DashboardService _service;

  DashboardData? _data;
  DashboardData? get data => _data;

  bool _loading = false;
  bool get loading => _loading;

  Object? _error;
  Object? get error => _error;

  bool _hasLoaded = false;
  bool get hasLoaded => _hasLoaded;

  DateTime? _loadedAt;
  int _loadSeq = 0;

  /// Dashboard content depends on the signed-in role; clear it when the session changes.
  void reset() {
    _loadSeq++;
    _data = null;
    _hasLoaded = false;
    _loadedAt = null;
    _error = null;
    _loading = false;
    notifyListeners();
  }

  Future<void> loadIfNeeded() async {
    if (_hasLoaded && _data != null && CacheStamp.isFresh(_loadedAt, CachePolicy.dashboardTtl)) return;
    await refresh(force: false);
  }

  Future<void> refresh({bool force = true}) async {
    if (!force && _hasLoaded && _data != null && CacheStamp.isFresh(_loadedAt, CachePolicy.dashboardTtl)) {
      return;
    }
    final seq = ++_loadSeq;
    _loading = _data == null;
    _error = null;
    notifyListeners();
    try {
      final result = await _service.fetchDashboard();
      if (seq != _loadSeq) return;
      _data = result;
      _hasLoaded = true;
      _loadedAt = DateTime.now();
      _error = null;
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
}
