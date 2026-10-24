import 'package:flutter/foundation.dart';

import 'package:attendance/core/cache/cache_policy.dart';
import 'package:attendance/core/cache/cache_stamp.dart';
import 'package:attendance/core/cache/hybrid_list_loader.dart';
import 'package:attendance/features/task/data/task_service.dart';

class TaskProvider extends ChangeNotifier {
  TaskProvider({TaskService? service}) : _service = service ?? TaskService();

  final TaskService _service;

  List<TaskItem> _tasks = <TaskItem>[];
  List<TaskItem> get tasks => _tasks;

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
    _loading = !_hasLoaded && _tasks.isEmpty;
    _refreshing = _tasks.isNotEmpty || _hasLoaded;
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
          _tasks = stale;
          _hasLoaded = true;
          _loading = false;
          _refreshing = true;
          _error = null;
          notifyListeners();
        },
      );
      if (seq != _loadSeq) return;
      _tasks = results;
      _hasLoaded = true;
      _loadedAt = DateTime.now();
      _error = null;
    } catch (e) {
      if (seq == _loadSeq && _tasks.isEmpty) {
        _error = e;
      }
    }
    if (seq == _loadSeq) {
      _loading = false;
      _refreshing = false;
      notifyListeners();
    }
  }

  Future<int?> create(TaskCreateInput input) async {
    _error = null;
    try {
      final id = await _service.create(input);
      await refresh();
      return id;
    } catch (e) {
      _error = e;
      notifyListeners();
      return null;
    }
  }

  Future<bool> updateTask(int taskId, Map<String, dynamic> body) async {
    _error = null;
    try {
      await _service.update(taskId: taskId, body: body);
      await refresh();
      return true;
    } catch (e) {
      _error = e;
      notifyListeners();
      return false;
    }
  }

  Future<bool> deleteTask(int taskId) async {
    _error = null;
    try {
      await _service.deleteRemote(taskId);
      await refresh();
      return true;
    } catch (e) {
      _error = e;
      notifyListeners();
      return false;
    }
  }

  Future<bool> changeStatus({required int taskId, required String status, String? comment}) async {
    _error = null;
    try {
      await _service.changeStatus(taskId: taskId, status: status, comment: comment);
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
    _tasks = <TaskItem>[];
    _hasLoaded = false;
    _loadedAt = null;
    _error = null;
    _loading = false;
    _refreshing = false;
    notifyListeners();
  }
}
