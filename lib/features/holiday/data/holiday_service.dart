import 'package:attendance/core/cache/cache_policy.dart';
import 'package:attendance/core/cache/cache_stamp.dart';
import 'package:attendance/core/utils/app_date_format.dart';
import 'package:attendance/services/api_client.dart';

class Holiday {
  const Holiday({
    required this.id,
    required this.name,
    required this.date,
    required this.day,
    required this.description,
    required this.isActive,
    this.createdByName,
    this.createdAt,
    this.updatedAt,
  });

  final int id;
  final String name;

  /// `yyyy-MM-dd`
  final String date;
  final String day;
  final String description;
  final bool isActive;
  final String? createdByName;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  DateTime? get dateValue => AppDateFormat.tryParse(date);

  static bool _toBool(Object? v) => v == true || v == 1 || v == '1' || v.toString().toLowerCase() == 'true';

  factory Holiday.fromJson(Map<String, dynamic> json) {
    final createdBy = json['created_by'];
    return Holiday(
      id: int.tryParse((json['id'] ?? '').toString()) ?? 0,
      name: (json['name'] ?? '').toString(),
      date: (json['date'] ?? '').toString(),
      day: (json['day'] ?? '').toString(),
      description: (json['description'] ?? '').toString(),
      isActive: json['is_active'] == null ? true : _toBool(json['is_active']),
      createdByName: createdBy is Map ? createdBy['name']?.toString() : null,
      createdAt: AppDateFormat.tryParse(json['created_at']?.toString()),
      updatedAt: AppDateFormat.tryParse(json['updated_at']?.toString()),
    );
  }
}

class HolidayService {
  HolidayService({ApiClient? apiClient}) : _api = apiClient ?? ApiClient();

  final ApiClient _api;

  static List<Holiday>? _cache;
  static DateTime? _cacheAt;

  Future<List<Holiday>> fetchAll({bool force = false}) async {
    if (!force && _cache != null && CacheStamp.isFresh(_cacheAt, CachePolicy.holidaysTtl)) {
      return _cache!;
    }
    final decoded = await _api.getJson('/api/v1/holidays');
    final data = decoded['data'];
    final list = data is List ? data : (data is Map && data['data'] is List ? data['data'] as List : const []);
    final parsed = [
      for (final e in list)
        if (e is Map<String, dynamic>) Holiday.fromJson(e),
    ]..sort((a, b) => a.date.compareTo(b.date));
    _cache = parsed;
    _cacheAt = DateTime.now();
    return parsed;
  }

  static void invalidateCache() {
    _cache = null;
    _cacheAt = null;
  }

  Future<Holiday> fetch(int id) async {
    final decoded = await _api.getJson('/api/v1/holidays/$id');
    final data = decoded['data'];
    if (data is! Map<String, dynamic>) throw Exception('Invalid response');
    return Holiday.fromJson(data);
  }

  Future<void> create({
    required String name,
    required String date,
    required String description,
    required bool isActive,
  }) async {
    await _api.postJson(
      '/api/v1/holidays',
      body: {'name': name, 'date': date, 'description': description, 'is_active': isActive},
    );
    invalidateCache();
  }

  Future<void> update(
    int id, {
    required String name,
    required String date,
    required String description,
    required bool isActive,
  }) async {
    await _api.postJson(
      '/api/v1/holidays/$id/update',
      body: {'name': name, 'date': date, 'description': description, 'is_active': isActive},
    );
    invalidateCache();
  }

  Future<void> delete(int id) async {
    await _api.postJson('/api/v1/holidays/$id/delete');
    invalidateCache();
  }
}
