import 'package:attendance/features/notification/data/notification_models.dart';
import 'package:attendance/services/api_client.dart';

export 'notification_models.dart';

class NotificationService {
  NotificationService({ApiClient? apiClient}) : _api = apiClient ?? ApiClient();

  final ApiClient _api;

  Future<NotificationListResult> fetchList() async {
    final decoded = await _api.getJson('/api/v1/notifications');
    final data = decoded['data'];
    if (data is! Map) throw Exception('Invalid response');
    final map = data.cast<String, dynamic>();
    final rawList = map['notifications'];
    final notifications = <AppNotification>[];
    if (rawList is List) {
      for (final item in rawList) {
        if (item is Map<String, dynamic>) {
          notifications.add(AppNotification.fromJson(item));
        } else if (item is Map) {
          notifications.add(AppNotification.fromJson(item.cast<String, dynamic>()));
        }
      }
    }
    final unread = int.tryParse((map['unread_count'] ?? '').toString()) ?? 0;
    return NotificationListResult(unreadCount: unread, notifications: notifications);
  }

  Future<void> markRead(int notificationId) async {
    await _api.postJson('/api/v1/notifications/$notificationId/read');
  }

  Future<void> markAllRead() async {
    await _api.postJson('/api/v1/notifications/read-all');
  }
}
