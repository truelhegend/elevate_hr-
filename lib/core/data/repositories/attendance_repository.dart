import '../datasources/api_service.dart';
import '../models/attendance.dart';

class AttendanceRepository {
  final ApiService api;

  AttendanceRepository({required this.api});

  Future<AttendanceRecord> clockIn() async {
    final response = await api.post('/attendance/clock-in');
    final data = response.data['data'];
    if (data == null) throw Exception('Failed to clock in');
    return AttendanceRecord.fromJson(data);
  }

  Future<AttendanceRecord> clockOut() async {
    final response = await api.post('/attendance/clock-out');
    final data = response.data['data'];
    if (data == null) throw Exception('Failed to clock out');
    return AttendanceRecord.fromJson(data);
  }

  Future<AttendanceRecord> markRemote() async {
    final response = await api.post('/attendance/mark-remote');
    final data = response.data['data'];
    if (data == null) throw Exception('Failed to mark remote');
    return AttendanceRecord.fromJson(data);
  }

  Future<List<AttendanceRecord>> getMyRecords({int page = 1, int limit = 20}) async {
    final response = await api.get('/attendance/my-records', queryParameters: {
      'page': page,
      'limit': limit,
    });
    final data = response.data['data'];
    if (data == null) return [];
    final items = data['data'] as List<dynamic>? ?? [];
    return items.map((e) => AttendanceRecord.fromJson(e as Map<String, dynamic>)).toList();
  }

  Future<List<Map<String, dynamic>>> getTodayAttendance() async {
    final response = await api.get('/attendance/today');
    final data = response.data['data'];
    if (data == null) return [];
    return List<Map<String, dynamic>>.from(data);
  }

  Future<Map<String, dynamic>> getAttendanceStats({String? startDate, String? endDate}) async {
    final params = <String, dynamic>{};
    if (startDate != null) params['startDate'] = startDate;
    if (endDate != null) params['endDate'] = endDate;

    final response = await api.get('/attendance/stats', queryParameters: params);
    return response.data['data'] ?? {};
  }

  Future<List<Map<String, dynamic>>> getTeamAvailability() async {
    final response = await api.get('/attendance/team-availability');
    final data = response.data['data'];
    if (data == null) return [];
    return List<Map<String, dynamic>>.from(data);
  }
}
