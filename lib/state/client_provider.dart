import 'package:flutter/foundation.dart';

import 'package:attendance/core/cache/cache_policy.dart';
import 'package:attendance/core/cache/cache_stamp.dart';
import 'package:attendance/core/cache/hybrid_list_loader.dart';
import 'package:attendance/features/client/data/client_service.dart';

class ClientProvider extends ChangeNotifier {
  ClientProvider({ClientService? service}) : _service = service ?? ClientService();

  final ClientService _service;

  List<Client> _clients = <Client>[];
  List<Client> get clients => _clients;

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
    _loading = !_hasLoaded && _clients.isEmpty;
    _refreshing = _clients.isNotEmpty || _hasLoaded;
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
          _clients = stale;
          _hasLoaded = true;
          _loading = false;
          _refreshing = true;
          notifyListeners();
        },
      );
      if (seq != _loadSeq) return;
      _clients = results;
      _hasLoaded = true;
      _loadedAt = DateTime.now();
      _error = null;
    } catch (e) {
      if (seq == _loadSeq && _clients.isEmpty) _error = e;
    }
    if (seq == _loadSeq) {
      _loading = false;
      _refreshing = false;
      notifyListeners();
    }
  }

  Future<bool> create(Client client) async {
    _loading = true;
    _error = null;
    notifyListeners();
    try {
      await _service.create(client);
      await refresh();
      return true;
    } catch (e) {
      _error = e;
      _loading = false;
      notifyListeners();
      return false;
    }
  }

  Future<bool> update(Client client) async {
    if (client.id <= 0) return false;
    _loading = true;
    _error = null;
    notifyListeners();
    try {
      await _service.update(clientId: client.id, client: client);
      await refresh();
      return true;
    } catch (e) {
      _error = e;
      _loading = false;
      notifyListeners();
      return false;
    }
  }

  Future<bool> deleteById(int clientId) async {
    _loading = true;
    _error = null;
    notifyListeners();
    try {
      await _service.deleteRemote(clientId);
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
    _clients = <Client>[];
    _hasLoaded = false;
    _loadedAt = null;
    _error = null;
    _loading = false;
    _refreshing = false;
    notifyListeners();
  }
}
