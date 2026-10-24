import 'dart:convert';

import 'package:attendance/core/cache/cache_policy.dart';
import 'package:attendance/services/directory_service.dart';
import 'package:attendance/services/local_storage_service.dart';
import 'package:attendance/services/storage_keys.dart';

/// In-memory TTL cache for meeting form directory picklists, with disk fallback.
class DirectoryCacheService {
  DirectoryCacheService({DirectoryService? remote, LocalStorageService? storage})
    : _remote = remote ?? DirectoryService(),
      _storage = storage ?? LocalStorageService.instance;

  static final DirectoryCacheService instance = DirectoryCacheService();

  static const Duration ttl = CachePolicy.directoryTtl;

  final DirectoryService _remote;
  final LocalStorageService _storage;

  List<DirectoryItem>? _leads;
  List<DirectoryItem>? _clients;
  List<DirectoryItem>? _employees;
  DateTime? _leadsAt;
  DateTime? _clientsAt;
  DateTime? _employeesAt;

  bool _diskHydrated = false;

  bool _isFresh(DateTime? at) {
    if (at == null) return false;
    return DateTime.now().difference(at) < ttl;
  }

  Future<void> _hydrateFromDiskOnce() async {
    if (_diskHydrated) return;
    _diskHydrated = true;

    final updatedMs = await _storage.getInt(StorageKeys.directoryCacheUpdatedAt);
    if (updatedMs == null) return;
    final updatedAt = DateTime.fromMillisecondsSinceEpoch(updatedMs);
    if (!_isFresh(updatedAt)) return;

    _leadsAt = updatedAt;
    _clientsAt = updatedAt;
    _employeesAt = updatedAt;

    _leads = await _readDiskList(StorageKeys.directoryLeadsCache);
    _clients = await _readDiskList(StorageKeys.directoryClientsCache);
    _employees = await _readDiskList(StorageKeys.directoryEmployeesCache);
  }

  Future<List<DirectoryItem>?> _readDiskList(String key) async {
    final raw = await _storage.getString(key);
    if (raw == null || raw.isEmpty) return null;
    try {
      final decoded = jsonDecode(raw) as List<dynamic>;
      return decoded
          .whereType<Map>()
          .map((e) => DirectoryItem.fromJson(e.cast<String, dynamic>()))
          .where((e) => e.id > 0)
          .toList();
    } catch (_) {
      return null;
    }
  }

  Future<void> _persistDisk({
    List<DirectoryItem>? leads,
    List<DirectoryItem>? clients,
    List<DirectoryItem>? employees,
  }) async {
    final now = DateTime.now();
    if (leads != null) {
      await _storage.setString(StorageKeys.directoryLeadsCache, jsonEncode(leads.map((e) => e.toJson()).toList()));
    }
    if (clients != null) {
      await _storage.setString(StorageKeys.directoryClientsCache, jsonEncode(clients.map((e) => e.toJson()).toList()));
    }
    if (employees != null) {
      await _storage.setString(
        StorageKeys.directoryEmployeesCache,
        jsonEncode(employees.map((e) => e.toJson()).toList()),
      );
    }
    await _storage.setInt(StorageKeys.directoryCacheUpdatedAt, now.millisecondsSinceEpoch);
  }

  Future<List<DirectoryItem>> leads({bool force = false}) async {
    await _hydrateFromDiskOnce();
    if (!force && _leads != null && _isFresh(_leadsAt)) {
      return _leads!;
    }
    final stale = _leads;
    try {
      _leads = await _remote.leads();
      _leadsAt = DateTime.now();
      await _persistDisk(leads: _leads);
      return _leads!;
    } catch (_) {
      if (stale != null && stale.isNotEmpty) return stale;
      rethrow;
    }
  }

  Future<List<DirectoryItem>> clients({bool force = false}) async {
    await _hydrateFromDiskOnce();
    if (!force && _clients != null && _isFresh(_clientsAt)) {
      return _clients!;
    }
    final stale = _clients;
    try {
      _clients = await _remote.clients();
      _clientsAt = DateTime.now();
      await _persistDisk(clients: _clients);
      return _clients!;
    } catch (_) {
      if (stale != null && stale.isNotEmpty) return stale;
      rethrow;
    }
  }

  Future<List<DirectoryItem>> employees({bool force = false}) async {
    await _hydrateFromDiskOnce();
    if (!force && _employees != null && _isFresh(_employeesAt)) {
      return _employees!;
    }
    final stale = _employees;
    try {
      _employees = await _remote.employees();
      _employeesAt = DateTime.now();
      await _persistDisk(employees: _employees);
      return _employees!;
    } catch (_) {
      if (stale != null && stale.isNotEmpty) return stale;
      rethrow;
    }
  }

  Future<({List<DirectoryItem> leads, List<DirectoryItem> clients, List<DirectoryItem> employees})> loadAll({
    bool force = false,
  }) async {
    final results = await Future.wait([leads(force: force), clients(force: force), employees(force: force)]);
    return (leads: results[0], clients: results[1], employees: results[2]);
  }

  void invalidate() {
    _leads = null;
    _clients = null;
    _employees = null;
    _leadsAt = null;
    _clientsAt = null;
    _employeesAt = null;
    _diskHydrated = false;
  }
}
