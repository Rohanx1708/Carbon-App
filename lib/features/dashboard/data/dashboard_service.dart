import 'package:attendance/features/dashboard/data/dashboard_models.dart';
import 'package:attendance/services/api_client.dart';

class DashboardService {
  DashboardService({ApiClient? apiClient}) : _api = apiClient ?? ApiClient();

  final ApiClient _api;

  Future<DashboardData> fetchDashboard() async {
    final decoded = await _api.getJson('/api/v1/dashboard');
    final data = decoded['data'];
    if (data is! Map<String, dynamic>) {
      throw Exception('Invalid response');
    }
    return DashboardData.fromJson(data);
  }
}
