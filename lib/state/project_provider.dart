import 'package:flutter/foundation.dart';

import 'package:attendance/core/cache/cache_policy.dart';
import 'package:attendance/core/cache/cache_stamp.dart';
import 'package:attendance/core/cache/hybrid_list_loader.dart';
import 'package:attendance/features/project/data/project_service.dart';

class ProjectProvider extends ChangeNotifier {
  ProjectProvider({ProjectService? service}) : _service = service ?? ProjectService();

  final ProjectService _service;

  List<Project> _projects = <Project>[];
  List<Project> get projects => _projects;

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
    _loading = !_hasLoaded && _projects.isEmpty;
    _refreshing = _projects.isNotEmpty || _hasLoaded;
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
          _projects = stale;
          _hasLoaded = true;
          _loading = false;
          _refreshing = true;
          notifyListeners();
        },
      );
      if (seq != _loadSeq) return;
      _projects = results;
      _hasLoaded = true;
      _loadedAt = DateTime.now();
      _error = null;
    } catch (e) {
      if (seq == _loadSeq && _projects.isEmpty) _error = e;
    }
    if (seq == _loadSeq) {
      _loading = false;
      _refreshing = false;
      notifyListeners();
    }
  }

  Future<bool> create(ProjectCreateRequest request) async {
    _loading = true;
    _error = null;
    notifyListeners();
    try {
      await _service.create(request);
      await refresh();
      return true;
    } catch (e) {
      _error = e;
      _loading = false;
      notifyListeners();
      return false;
    }
  }

  Future<bool> updateFields({required int projectId, required Map<String, dynamic> body}) async {
    _loading = true;
    _error = null;
    notifyListeners();
    try {
      await _service.update(projectId: projectId, body: body);
      await refresh();
      return true;
    } catch (e) {
      _error = e;
      _loading = false;
      notifyListeners();
      return false;
    }
  }

  Future<bool> deleteById(int projectId) async {
    _loading = true;
    _error = null;
    notifyListeners();
    try {
      await _service.deleteRemote(projectId);
      await refresh();
      return true;
    } catch (e) {
      _error = e;
      _loading = false;
      notifyListeners();
      return false;
    }
  }

  void clearSession() {
    _loadSeq++;
    _projects = <Project>[];
    _hasLoaded = false;
    _loadedAt = null;
    _error = null;
    _loading = false;
    _refreshing = false;
    notifyListeners();
  }
}
