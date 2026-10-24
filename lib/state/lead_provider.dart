import 'package:flutter/foundation.dart';

import 'package:attendance/core/cache/cache_policy.dart';
import 'package:attendance/core/cache/cache_stamp.dart';
import 'package:attendance/core/cache/hybrid_list_loader.dart';
import 'package:attendance/features/lead/data/lead_service.dart';

class LeadProvider extends ChangeNotifier {
  LeadProvider({LeadService? service}) : _service = service ?? LeadService();

  final LeadService _service;

  List<Lead> _leads = <Lead>[];
  List<Lead> get leads => _leads;

  bool _loading = false;
  bool get loading => _loading;

  bool _refreshing = false;
  bool get refreshing => _refreshing;

  Object? _error;
  Object? get error => _error;

  bool _hasLoaded = false;
  bool get hasLoaded => _hasLoaded;

  LeadListQuery _lastQuery = const LeadListQuery();

  DateTime? _loadedAt;
  int _loadSeq = 0;

  Future<void> loadIfNeeded({String? status, String? stage, String? source, String? search}) async {
    final query = LeadListQuery(status: status, stage: stage, source: source, search: search);
    if (_hasLoaded && _lastQuery.matches(query) && CacheStamp.isFresh(_loadedAt, CachePolicy.listTtl)) {
      return;
    }
    await load(status: status, stage: stage, source: source, search: search, force: false);
  }

  Future<void> load({String? status, String? stage, String? source, String? search, bool force = true}) async {
    final query = LeadListQuery(status: status, stage: stage, source: source, search: search);
    _lastQuery = query;
    final seq = ++_loadSeq;
    _error = null;
    _loading = !_hasLoaded && _leads.isEmpty;
    _refreshing = _leads.isNotEmpty || _hasLoaded;
    notifyListeners();

    try {
      final results = await HybridListLoader.load(
        readLocal: () async {
          final local = await _service.readLocal();
          return _service.filterLocalList(local, query: query);
        },
        fetchRemote: () => _service.fetchAllRemote(query: query),
        readUpdatedAt: _service.readLocalUpdatedAt,
        ttl: CachePolicy.listTtl,
        force: force,
        onStale: (stale) {
          if (seq != _loadSeq) return;
          _leads = stale;
          _hasLoaded = true;
          _loading = false;
          _refreshing = true;
          notifyListeners();
        },
      );
      if (seq != _loadSeq) return;
      _leads = results;
      _hasLoaded = true;
      _loadedAt = DateTime.now();
      _error = null;
    } catch (e) {
      if (seq == _loadSeq && _leads.isEmpty) {
        _error = e;
      }
    }
    if (seq == _loadSeq) {
      _loading = false;
      _refreshing = false;
      notifyListeners();
    }
  }

  Future<void> reloadLastQuery() =>
      load(status: _lastQuery.status, stage: _lastQuery.stage, source: _lastQuery.source, search: _lastQuery.search);

  Future<bool> add(Lead lead) async {
    _loading = true;
    _error = null;
    notifyListeners();
    try {
      await _service.add(lead);
      await reloadLastQuery();
      return true;
    } catch (e) {
      _error = e;
      _loading = false;
      notifyListeners();
      return false;
    }
  }

  Future<bool> update(Lead lead) async {
    final id = lead.id;
    if (id == null) {
      _error = Exception('Lead id not available');
      notifyListeners();
      return false;
    }

    _loading = true;
    _error = null;
    notifyListeners();
    try {
      await _service.updateRemote(leadId: id, lead: lead);
      await reloadLastQuery();
      return true;
    } catch (e) {
      _error = e;
      _loading = false;
      notifyListeners();
      return false;
    }
  }

  Future<bool> deleteById(int leadId) async {
    _loading = true;
    _error = null;
    notifyListeners();
    try {
      await _service.deleteRemote(leadId);
      await reloadLastQuery();
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
    await reloadLastQuery();
  }

  void clearSession() {
    _loadSeq++;
    _leads = <Lead>[];
    _hasLoaded = false;
    _loadedAt = null;
    _error = null;
    _loading = false;
    _refreshing = false;
    notifyListeners();
  }
}
