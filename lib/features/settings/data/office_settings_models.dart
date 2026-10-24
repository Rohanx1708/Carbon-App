import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

/// Organisation-wide office settings: hours, week offs, leave quota and geofence.
class OfficeSettings {
  const OfficeSettings({
    required this.id,
    required this.startTime,
    required this.endTime,
    required this.geofenceEnabled,
    required this.latitude,
    required this.longitude,
    required this.geofenceRadius,
    required this.weekOffs,
    required this.weekOffDays,
    required this.annualLeaveQuota,
    required this.updatedAt,
  });

  final int id;

  /// `HH:mm`
  final String startTime;

  /// `HH:mm`
  final String endTime;
  final bool geofenceEnabled;
  final double? latitude;
  final double? longitude;

  /// Metres.
  final double geofenceRadius;

  /// 0 = Sunday … 6 = Saturday.
  final List<int> weekOffs;
  final List<String> weekOffDays;
  final int annualLeaveQuota;
  final DateTime updatedAt;

  static const weekdayLabels = ['Sun', 'Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat'];

  /// True when the geofence is on and has a usable centre point.
  bool get hasActiveGeofence => geofenceEnabled && latitude != null && longitude != null && geofenceRadius > 0;

  static double? _toDouble(Object? v) => v == null ? null : double.tryParse(v.toString());

  static bool _toBool(Object? v) => v == true || v == 1 || v == '1' || v.toString().toLowerCase() == 'true';

  factory OfficeSettings.fromJson(Map<String, dynamic> json) => OfficeSettings(
    id: int.tryParse((json['id'] ?? '').toString()) ?? 0,
    startTime: (json['start_time'] ?? '').toString(),
    endTime: (json['end_time'] ?? '').toString(),
    geofenceEnabled: _toBool(json['geofence_enabled']),
    latitude: _toDouble(json['latitude']),
    longitude: _toDouble(json['longitude']),
    geofenceRadius: _toDouble(json['geofence_radius']) ?? 100,
    weekOffs: [for (final v in (json['week_offs'] as List? ?? const [])) ?int.tryParse(v.toString())],
    weekOffDays: [for (final v in (json['week_off_days'] as List? ?? const [])) v.toString()],
    annualLeaveQuota: int.tryParse((json['annual_leave_quota'] ?? '').toString()) ?? 0,
    updatedAt: parseApiDateTime((json['updated_at'] ?? '').toString()),
  );

  static DateTime parseApiDateTime(String raw) {
    final parsed = DateTime.tryParse(raw);
    if (parsed != null) return parsed;
    try {
      return DateFormat('yyyy-MM-dd HH:mm:ss').parse(raw, true).toLocal();
    } catch (_) {
      return DateTime.now();
    }
  }

  static TimeOfDay? parseTime(String raw) {
    final trimmed = raw.trim();
    if (trimmed.isEmpty) return null;
    final parts = trimmed.split(':');
    if (parts.length < 2) return null;
    final hour = int.tryParse(parts[0]);
    final minute = int.tryParse(parts[1]);
    if (hour == null || minute == null) return null;
    if (hour < 0 || hour > 23 || minute < 0 || minute > 59) return null;
    return TimeOfDay(hour: hour, minute: minute);
  }

  static String formatTime(TimeOfDay time) {
    final h = time.hour.toString().padLeft(2, '0');
    final m = time.minute.toString().padLeft(2, '0');
    return '$h:$m';
  }

  static String displayTime(String apiTime) {
    final t = parseTime(apiTime);
    if (t == null) return apiTime.isEmpty ? '—' : apiTime;
    final dt = DateTime(2000, 1, 1, t.hour, t.minute);
    return DateFormat.jm().format(dt);
  }
}
