import 'package:attendance/services/local_storage_service.dart';

/// Helpers for reading and evaluating cache timestamps.
abstract final class CacheStamp {
  static Future<DateTime?> read(LocalStorageService storage, String key) async {
    final ms = await storage.getInt(key);
    if (ms == null) return null;
    return DateTime.fromMillisecondsSinceEpoch(ms);
  }

  static Future<void> write(LocalStorageService storage, String key, [DateTime? at]) async {
    await storage.setInt(key, (at ?? DateTime.now()).millisecondsSinceEpoch);
  }

  static bool isFresh(DateTime? at, Duration ttl) {
    if (at == null) return false;
    return DateTime.now().difference(at) < ttl;
  }
}
