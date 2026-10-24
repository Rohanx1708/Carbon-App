import 'package:intl/intl.dart';

import 'package:attendance/features/daily_report/data/daily_report_models.dart';
import 'package:attendance/services/api_client.dart';

class DailyReportService {
  DailyReportService({ApiClient? apiClient}) : _api = apiClient ?? ApiClient();

  final ApiClient _api;
  static final _ymd = DateFormat('yyyy-MM-dd');

  List<DailyWorkReport> _parseList(Object? data) {
    if (data is! List) throw Exception('Invalid response');
    return data
        .whereType<Map>()
        .map((e) => DailyWorkReport.fromJson(e.cast<String, dynamic>()))
        .where((r) => r.id > 0)
        .toList()
      ..sort((a, b) => b.reportDate.compareTo(a.reportDate));
  }

  /// Current user's reports: `GET /api/v1/work-reports/my?date=yyyy-MM-dd`
  Future<List<DailyWorkReport>> fetchMy({DateTime? date, DateTime? to}) async {
    final q = <String, String>{};
    if (date != null) q['date'] = _ymd.format(date);
    if (to != null) q['to'] = _ymd.format(to);
    final decoded = await _api.getJson(
      '/api/v1/work-reports/my',
      queryParameters: q.isEmpty ? null : q,
    );
    return _parseList(decoded['data']);
  }

  /// Index / team list: `GET /api/v1/work-reports`
  Future<List<DailyWorkReport>> fetchIndex({DateTime? date}) async {
    final decoded = await _api.getJson(
      '/api/v1/work-reports',
      queryParameters: date == null ? null : {'date': _ymd.format(date)},
    );
    return _parseList(decoded['data']);
  }

  Future<DailyWorkReport> fetchDetail(int id) async {
    final decoded = await _api.getJson('/api/v1/work-reports/$id');
    final data = decoded['data'];
    if (data is! Map<String, dynamic>) throw Exception('Invalid response');
    return DailyWorkReport.fromJson(data);
  }

  /// Create: `POST /api/v1/work-reports`
  Future<void> submit({
    required DateTime date,
    required List<int> projectIds,
    required String workDone,
  }) async {
    await _api.postJson(
      '/api/v1/work-reports',
      body: {
        'report_date': _ymd.format(date),
        'work_done': workDone,
        'project_ids': projectIds,
      },
    );
  }

  /// Update: `POST /api/v1/work-reports/{id}/update`
  Future<void> update({
    required int id,
    required List<int> projectIds,
    required String workDone,
    DateTime? date,
  }) async {
    final body = <String, dynamic>{
      'work_done': workDone,
      'project_ids': projectIds,
    };
    if (date != null) body['report_date'] = _ymd.format(date);
    await _api.postJson('/api/v1/work-reports/$id/update', body: body);
  }
}
