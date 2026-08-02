import '../datasources/api_service.dart';
import '../models/performance.dart';

class PerformanceRepository {
  final ApiService api;

  PerformanceRepository({required this.api});

  Future<PerformanceData> getMyScore() async {
    final response = await api.get('/performance/my-score');
    final data = response.data['data'];
    if (data == null) throw Exception('No performance score found');
    return PerformanceData.fromJson(data);
  }

  Future<List<PerformanceTrend>> getMyHistory({int months = 12}) async {
    final response = await api.get('/performance/my-history', queryParameters: {
      'months': months,
    });
    final data = response.data['data'];
    if (data == null) return [];
    final items = data as List<dynamic>;
    return items.map((e) => PerformanceTrend.fromJson(e as Map<String, dynamic>)).toList();
  }

  Future<List<Map<String, dynamic>>> getTeamPerformance() async {
    final response = await api.get('/performance/team');
    final data = response.data['data'];
    if (data == null) return [];
    return List<Map<String, dynamic>>.from(data);
  }

  Future<Map<String, dynamic>> getDepartmentPerformance(String departmentId) async {
    final response = await api.get('/performance/department/$departmentId');
    return response.data['data'] ?? {};
  }

  Future<Map<String, dynamic>> getCompanyPerformance(String companyId) async {
    final response = await api.get('/performance/company/$companyId');
    return response.data['data'] ?? {};
  }
}
