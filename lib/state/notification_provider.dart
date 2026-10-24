import 'package:flutter/foundation.dart';

import 'package:attendance/core/cache/cache_policy.dart';
import 'package:attendance/core/cache/cache_stamp.dart';
import 'package:attendance/features/notification/data/notification_service.dart';

class NotificationProvider extends ChangeNotifier {
  NotificationProvider({NotificationService? service}) : _service = service ?? NotificationService();

  final NotificationService _service;

  List<AppNotification> _notifications = [];
  List<AppNotification> get notifications => _notifications;

  int _unreadCount = 0;
  int get unreadCount => _unreadCount;

  bool _loading = false;
  bool get loading => _loading;

  bool _refreshing = false;
  bool get refreshing => _refreshing;

  Object? _error;
  Object? get error => _error;

  bool _hasLoaded = false;
  bool get hasLoaded => _hasLoaded;

  DateTime? _loadedAt;

  Future<void> loadIfNeeded() async {
    if (_hasLoaded && CacheStamp.isFresh(_loadedAt, CachePolicy.notificationsTtl)) return;
    await refresh(force: false);
  }

  Future<void> refresh({bool force = true}) async {
    if (!force && _hasLoaded && CacheStamp.isFresh(_loadedAt, CachePolicy.notificationsTtl)) {
      return;
    }
    _error = null;
    if (!_hasLoaded) {
      _loading = true;
    } else {
      _refreshing = true;
    }
    notifyListeners();
    try {
      final result = await _service.fetchList();
      _notifications = result.notifications;
      _unreadCount = result.unreadCount;
      _loadedAt = DateTime.now();
    } catch (e) {
      _error = e;
    }
    _loading = false;
    _refreshing = false;
    _hasLoaded = true;
    notifyListeners();
  }

  Future<void> markRead(int notificationId) async {
    final i = _notifications.indexWhere((n) => n.id == notificationId);
    if (i < 0) return;
    if (_notifications[i].isRead) return;

    _notifications = [
      for (var j = 0; j < _notifications.length; j++)
        if (j == i) _notifications[j].copyWith(isRead: true, readAt: DateTime.now()) else _notifications[j],
    ];
    if (_unreadCount > 0) _unreadCount -= 1;
    notifyListeners();

    try {
      await _service.markRead(notificationId);
    } catch (e) {
      await refresh();
    }
  }

  bool get hasUnread => _unreadCount > 0 || _notifications.any((n) => !n.isRead);

  Future<bool> markAllRead() async {
    if (!hasUnread) return false;
    final previous = _notifications;
    final previousUnread = _unreadCount;
    _notifications = [for (final n in _notifications) n.isRead ? n : n.copyWith(isRead: true, readAt: DateTime.now())];
    _unreadCount = 0;
    notifyListeners();
    try {
      await _service.markAllRead();
      return true;
    } catch (e) {
      _notifications = previous;
      _unreadCount = previousUnread;
      _error = e;
      notifyListeners();
      await refresh();
      return false;
    }
  }

  void clearSession() {
    _notifications = [];
    _unreadCount = 0;
    _hasLoaded = false;
    _loadedAt = null;
    _error = null;
    _loading = false;
    _refreshing = false;
    notifyListeners();
  }
}
