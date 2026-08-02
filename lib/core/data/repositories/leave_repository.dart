import '../datasources/api_service.dart';
import '../models/leave.dart';

class LeaveRepository {
  final ApiService api;

  LeaveRepository({required this.api});

  Future<List<LeaveRequest>> getLeaveRequests({String? status, String? employeeId, String? departmentId, String? leaveType, int page = 1, int limit = 20}) async {
    final params = <String, dynamic>{
      'page': page,
      'limit': limit,
    };
    if (status != null) params['status'] = status;
    if (employeeId != null) params['employeeId'] = employeeId;
    if (departmentId != null) params['departmentId'] = departmentId;
    if (leaveType != null) params['leaveType'] = leaveType;

    final response = await api.get('/leave/requests', queryParameters: params);
    final data = response.data['data'];
    if (data == null) return [];
    final items = data['data'] as List<dynamic>? ?? [];
    return items.map((e) => LeaveRequest.fromJson(e as Map<String, dynamic>)).toList();
  }

  Future<List<LeaveRequest>> getMyLeaveRequests({String? status, int page = 1, int limit = 20}) async {
    final params = <String, dynamic>{
      'page': page,
      'limit': limit,
    };
    if (status != null) params['status'] = status;

    final response = await api.get('/leave/my-requests', queryParameters: params);
    final data = response.data['data'];
    if (data == null) return [];
    final items = data['data'] as List<dynamic>? ?? [];
    return items.map((e) => LeaveRequest.fromJson(e as Map<String, dynamic>)).toList();
  }

  Future<List<LeaveRequest>> getPendingApprovals({int page = 1, int limit = 20}) async {
    final response = await api.get('/leave/pending-approvals', queryParameters: {
      'page': page,
      'limit': limit,
    });
    final data = response.data['data'];
    if (data == null) return [];
    final items = data['data'] as List<dynamic>? ?? [];
    return items.map((e) => LeaveRequest.fromJson(e as Map<String, dynamic>)).toList();
  }

  Future<LeaveRequest> submitLeaveRequest({required String leaveType, required DateTime startDate, required DateTime endDate, required String reason, String? documentUrl}) async {
    final body = <String, dynamic>{
      'leaveType': leaveType.toUpperCase(),
      'startDate': startDate.toIso8601String(),
      'endDate': endDate.toIso8601String(),
      'reason': reason,
    };
    if (documentUrl != null) body['documentUrl'] = documentUrl;

    final response = await api.post('/leave/request', data: body);
    final data = response.data['data'];
    if (data == null) throw Exception('Failed to submit leave request');
    return LeaveRequest.fromJson(data);
  }

  Future<LeaveRequest> approveLeave(String id, {String? comment}) async {
    final body = <String, dynamic>{};
    if (comment != null) body['comment'] = comment;

    final response = await api.patch('/leave/$id/approve', data: body);
    final data = response.data['data'];
    if (data == null) throw Exception('Failed to approve leave');
    return LeaveRequest.fromJson(data);
  }

  Future<LeaveRequest> rejectLeave(String id, {String? comment}) async {
    final body = <String, dynamic>{};
    if (comment != null) body['comment'] = comment;

    final response = await api.patch('/leave/$id/reject', data: body);
    final data = response.data['data'];
    if (data == null) throw Exception('Failed to reject leave');
    return LeaveRequest.fromJson(data);
  }

  Future<void> cancelLeave(String id) async {
    await api.patch('/leave/$id/cancel');
  }

  Future<List<LeaveBalance>> getLeaveBalance({int? year}) async {
    final params = <String, dynamic>{};
    if (year != null) params['year'] = year;

    final response = await api.get('/leave/balance', queryParameters: params);
    final data = response.data['data'];
    if (data == null) return [];
    final items = data as List<dynamic>;
    return items.map((e) => LeaveBalance.fromJson(e as Map<String, dynamic>)).toList();
  }
}
