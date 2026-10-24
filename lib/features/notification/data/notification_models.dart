import 'package:intl/intl.dart';

class AppNotification {
  const AppNotification({
    required this.id,
    required this.type,
    required this.title,
    required this.message,
    required this.data,
    required this.isRead,
    this.readAt,
    required this.createdAt,
  });

  final int id;
  final String type;
  final String title;
  final String message;
  final Map<String, dynamic> data;
  final bool isRead;
  final DateTime? readAt;
  final DateTime createdAt;

  AppNotification copyWith({bool? isRead, DateTime? readAt}) => AppNotification(
    id: id,
    type: type,
    title: title,
    message: message,
    data: data,
    isRead: isRead ?? this.isRead,
    readAt: readAt ?? this.readAt,
    createdAt: createdAt,
  );

  int? dataInt(List<String> keys) {
    for (final key in keys) {
      final v = int.tryParse((data[key] ?? '').toString());
      if (v != null && v > 0) return v;
    }
    return null;
  }

  static DateTime parseApiDateTime(String raw) {
    final parsed = DateTime.tryParse(raw);
    if (parsed != null) return parsed;
    try {
      return DateFormat('yyyy-MM-dd HH:mm:ss').parse(raw, true).toLocal();
    } catch (_) {
      return DateTime.now();
    }
  }

  factory AppNotification.fromJson(Map<String, dynamic> json) {
    final readRaw = json['read_at'] as String?;
    final dataRaw = json['data'];
    return AppNotification(
      id: int.tryParse((json['id'] ?? '').toString()) ?? 0,
      type: (json['type'] as String?) ?? '',
      title: (json['title'] as String?) ?? '',
      message: (json['message'] as String?) ?? '',
      data: dataRaw is Map<String, dynamic>
          ? dataRaw
          : dataRaw is Map
          ? dataRaw.cast<String, dynamic>()
          : const {},
      isRead: json['is_read'] as bool? ?? readRaw != null,
      readAt: readRaw != null && readRaw.isNotEmpty ? parseApiDateTime(readRaw) : null,
      createdAt: parseApiDateTime((json['created_at'] as String?) ?? ''),
    );
  }
}

class NotificationListResult {
  const NotificationListResult({required this.unreadCount, required this.notifications});

  final int unreadCount;
  final List<AppNotification> notifications;
}
