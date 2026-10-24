import 'package:flutter/foundation.dart';

import 'package:attendance/core/cache/cache_policy.dart';
import 'package:attendance/core/cache/cache_stamp.dart';
import 'package:attendance/core/cache/hybrid_list_loader.dart';
import 'package:attendance/features/leave_request/data/leave_request_service.dart';

class LeaveRequestProvider extends ChangeNotifier {
  LeaveRequestProvider({LeaveRequestService? service}) : _service = service ?? LeaveRequestService();

  final LeaveRequestService _service;

  List<LeaveRequestItem> _requests = <LeaveRequestItem>[];
  List<LeaveRequestItem> get requests => _requests;

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
    await refresh(force: false);
  }

  Future<void> refresh({bool force = true}) async {
    final seq = ++_loadSeq;
    _error = null;
    _loading = !_hasLoaded && _requests.isEmpty;
    _refreshing = _requests.isNotEmpty || _hasLoaded;
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
          _requests = stale;
          _hasLoaded = true;
          _loading = false;
          _refreshing = true;
          _error = null;
          notifyListeners();
        },
      );
      if (seq != _loadSeq) return;
      _requests = results;
      _hasLoaded = true;
      _loadedAt = DateTime.now();
      _error = null;
    } catch (e) {
      if (seq == _loadSeq && _requests.isEmpty) {
        _error = e;
      }
    }
    if (seq == _loadSeq) {
      _loading = false;
      _refreshing = false;
      notifyListeners();
    }
  }

  Future<bool> approve({required int requestId, required String reviewNote}) async {
    try {
      await _service.approve(requestId: requestId, reviewNote: reviewNote);
      await refresh();
      return true;
    } catch (e) {
      _error = e;
      notifyListeners();
      return false;
    }
  }

  Future<bool> reject({required int requestId, required String reviewNote}) async {
    try {
      await _service.reject(requestId: requestId, reviewNote: reviewNote);
      await refresh();
      return true;
    } catch (e) {
      _error = e;
      notifyListeners();
      return false;
    }
  }

  Future<bool> submit({required String startDate, required String endDate, required String reason}) async {
    try {
      await _service.submit(startDate: startDate, endDate: endDate, reason: reason);
      await refresh();
      return true;
    } catch (e) {
      _error = e;
      notifyListeners();
      return false;
    }
  }

  Future<bool> cancel({required int requestId, required String cancelReason}) async {
    try {
      await _service.cancel(requestId: requestId, cancelReason: cancelReason);
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
    _requests = <LeaveRequestItem>[];
    _hasLoaded = false;
    _loadedAt = null;
    _error = null;
    _loading = false;
    _refreshing = false;
    notifyListeners();
  }
}
