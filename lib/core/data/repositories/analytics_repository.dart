import '../datasources/api_service.dart';

class AnalyticsRepository {
  final ApiService api;

  AnalyticsRepository({required this.api});

  Future<Map<String, dynamic>> getDashboardStats() async {
    final response = await api.get('/analytics/dashboard');
    return response.data['data'] ?? {};
  }

  Future<List<Map<String, dynamic>>> getDepartmentRankings() async {
    final response = await api.get('/analytics/department-rankings');
    final data = response.data['data'];
    if (data == null) return [];
    return List<Map<String, dynamic>>.from(data);
  }

  Future<List<Map<String, dynamic>>> getLeaveTrends({int months = 6}) async {
    final response = await api.get('/analytics/leave-trends', queryParameters: {
      'months': months,
    });
    final data = response.data['data'];
    if (data == null) return [];
    return List<Map<String, dynamic>>.from(data);
  }

  Future<Map<String, dynamic>> getAbsenteeism() async {
    final response = await api.get('/analytics/absenteeism');
    return response.data['data'] ?? {};
  }

  Future<Map<String, dynamic>> getInsights() async {
    final response = await api.get('/analytics/insights');
    return response.data['data'] ?? {};
  }
}
