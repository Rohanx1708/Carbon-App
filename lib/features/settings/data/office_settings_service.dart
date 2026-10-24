import 'package:attendance/core/cache/cache_policy.dart';
import 'package:attendance/core/cache/cache_stamp.dart';
import 'package:attendance/features/settings/data/office_settings_models.dart';
import 'package:attendance/services/api_client.dart';

export 'office_settings_models.dart';

class OfficeSettingsService {
  OfficeSettingsService({ApiClient? apiClient}) : _api = apiClient ?? ApiClient();

  final ApiClient _api;

  /// Last settings seen by any instance, so screens can render week offs immediately.
  static OfficeSettings? cached;
  static DateTime? cachedAt;

  Future<OfficeSettings> fetch({bool force = false}) async {
    if (!force && cached != null && CacheStamp.isFresh(cachedAt, CachePolicy.settingsTtl)) {
      return cached!;
    }
    final decoded = await _api.getJson('/api/v1/office-settings');
    final data = decoded['data'];
    if (data is! Map<String, dynamic>) {
      throw Exception('Invalid response');
    }
    cached = OfficeSettings.fromJson(data);
    cachedAt = DateTime.now();
    return cached!;
  }

  Future<OfficeSettings> update({
    required String startTime,
    required String endTime,
    required List<int> weekOffs,
    required int annualLeaveQuota,
    required bool geofenceEnabled,
    double? latitude,
    double? longitude,
    required double geofenceRadius,
  }) async {
    final decoded = await _api.postJson(
      '/api/v1/office-settings/update',
      body: {
        'start_time': startTime,
        'end_time': endTime,
        'week_offs': weekOffs,
        'annual_leave_quota': annualLeaveQuota,
        'geofence_enabled': geofenceEnabled,
        'latitude': latitude,
        'longitude': longitude,
        'geofence_radius': geofenceRadius,
      },
    );
    final data = decoded['data'];
    if (data is Map<String, dynamic>) {
      cached = OfficeSettings.fromJson(data);
      cachedAt = DateTime.now();
      return cached!;
    }
    return fetch(force: true);
  }
}
