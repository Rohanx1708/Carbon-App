import 'package:flutter/foundation.dart';

import 'package:attendance/core/cache/cache_policy.dart';
import 'package:attendance/core/cache/cache_stamp.dart';
import 'package:attendance/core/cache/hybrid_list_loader.dart';
import 'package:attendance/features/meeting/data/meeting_service.dart';

class MeetingProvider extends ChangeNotifier {
  MeetingProvider({MeetingService? service}) : _service = service ?? MeetingService();

  final MeetingService _service;

  List<Meeting> _meetings = <Meeting>[];
  List<Meeting> get meetings => _meetings;

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
    _loading = !_hasLoaded && _meetings.isEmpty;
    _refreshing = _meetings.isNotEmpty || _hasLoaded;
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
          _meetings = stale;
          _hasLoaded = true;
          _loading = false;
          _refreshing = true;
          _error = null;
          notifyListeners();
        },
      );
      if (seq != _loadSeq) return;
      _meetings = results;
      _hasLoaded = true;
      _loadedAt = DateTime.now();
      _error = null;
    } catch (e) {
      if (seq == _loadSeq) {
        if (_meetings.isEmpty) {
          _error = e;
        }
        _hasLoaded = _meetings.isNotEmpty;
      }
    }
    if (seq == _loadSeq) {
      _loading = false;
      _refreshing = false;
      notifyListeners();
    }
  }

  /// Loads meetings for a single calendar day (`GET /meetings/date`).
  Future<void> loadDay(DateTime day) async {
    _refreshing = true;
    notifyListeners();
    try {
      await _service.fetchByDate(day);
      _meetings = await _service.readLocal();
      _error = null;
      _hasLoaded = true;
    } catch (e) {
      _error = e;
    }
    _refreshing = false;
    notifyListeners();
  }

  /// Loads meetings in a date range (`GET /meetings/date-range`) and merges cache.
  Future<void> loadDateRange({required DateTime start, required DateTime end}) async {
    _refreshing = true;
    notifyListeners();
    try {
      await _service.fetchByDateRange(start: start, end: end);
      _meetings = await _service.readLocal();
      _error = null;
      _hasLoaded = true;
    } catch (e) {
      _error = e;
    }
    _refreshing = false;
    notifyListeners();
  }

  Future<bool> add(Meeting meeting) async {
    _loading = true;
    _error = null;
    notifyListeners();
    try {
      await _service.add(meeting);
      await refresh();
      return true;
    } catch (e) {
      _error = e;
      _loading = false;
      notifyListeners();
      return false;
    }
  }

  /// Creates meeting and returns new id (for document uploads).
  Future<int?> addAndGetId(Meeting meeting) async {
    _error = null;
    try {
      final id = await _service.add(meeting);
      await refresh();
      return id;
    } catch (e) {
      _error = e;
      notifyListeners();
      return null;
    }
  }

  Future<bool> update(Meeting meeting) async {
    _loading = true;
    _error = null;
    notifyListeners();
    try {
      await _service.update(meeting);
      await refresh();
      return true;
    } catch (e) {
      _error = e;
      _loading = false;
      notifyListeners();
      return false;
    }
  }

  Future<bool> deleteById(int meetingId) async {
    _loading = true;
    _error = null;
    notifyListeners();
    try {
      await _service.deleteById(meetingId);
      await refresh();
      return true;
    } catch (e) {
      _error = e;
      _loading = false;
      notifyListeners();
      return false;
    }
  }

  Future<void> deleteAt(int index) async {
    await _service.deleteAt(index);
    await refresh();
  }

  void clearSession() {
    _loadSeq++;
    _meetings = <Meeting>[];
    _hasLoaded = false;
    _loadedAt = null;
    _error = null;
    _loading = false;
    _refreshing = false;
    notifyListeners();
  }
}
