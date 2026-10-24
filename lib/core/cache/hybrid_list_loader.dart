import 'package:attendance/core/cache/cache_policy.dart';
import 'package:attendance/core/cache/cache_stamp.dart';

/// Stale-while-revalidate helper for list data (local disk first, then network).
///
/// When [readUpdatedAt] + [ttl] mark local data as fresh and [force] is false,
/// the network call is skipped.
abstract final class HybridListLoader {
  static Future<List<T>> load<T>({
    required Future<List<T>> Function() readLocal,
    required Future<List<T>> Function() fetchRemote,
    void Function(List<T> stale)? onStale,
    Future<DateTime?> Function()? readUpdatedAt,
    Duration ttl = CachePolicy.listTtl,
    bool force = false,
  }) async {
    final local = await readLocal();
    final updatedAt = readUpdatedAt == null ? null : await readUpdatedAt();
    final fresh = !force && local.isNotEmpty && CacheStamp.isFresh(updatedAt, ttl);

    if (fresh) {
      return local;
    }

    if (local.isNotEmpty) {
      onStale?.call(local);
    }

    try {
      return await fetchRemote();
    } catch (_) {
      if (local.isNotEmpty) return local;
      rethrow;
    }
  }
}
