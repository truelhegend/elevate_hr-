import '../datasources/api_service.dart';
import '../models/user.dart';

class EmployeeRepository {
  final ApiService api;

  EmployeeRepository({required this.api});

  Future<User> getProfile() async {
    final response = await api.get('/employees/me');
    final data = response.data['data'];
    if (data == null) throw Exception('Failed to get profile');
    return User.fromJson(data);
  }

  Future<User> getEmployee(String id) async {
    final response = await api.get('/employees/$id');
    final data = response.data['data'];
    if (data == null) throw Exception('Employee not found');
    return User.fromJson(data);
  }

  Future<List<User>> getEmployees({String? departmentId, String? role, String? search, int page = 1, int limit = 20}) async {
    final params = <String, dynamic>{
      'page': page,
      'limit': limit,
    };
    if (departmentId != null) params['departmentId'] = departmentId;
    if (role != null) params['role'] = role;
    if (search != null) params['search'] = search;

    final response = await api.get('/employees', queryParameters: params);
    final data = response.data['data'];
    if (data == null) return [];
    final items = data['data'] as List<dynamic>? ?? [];
    return items.map((e) => User.fromJson(e as Map<String, dynamic>)).toList();
  }

  Future<User> updateProfile(String id, {String? firstName, String? lastName, String? phone, String? position, String? departmentId, String? avatarUrl}) async {
    final body = <String, dynamic>{};
    if (firstName != null) body['firstName'] = firstName;
    if (lastName != null) body['lastName'] = lastName;
    if (phone != null) body['phone'] = phone;
    if (position != null) body['position'] = position;
    if (departmentId != null) body['departmentId'] = departmentId;
    if (avatarUrl != null) body['avatarUrl'] = avatarUrl;

    final response = await api.patch('/employees/$id', data: body);
    final data = response.data['data'];
    if (data == null) throw Exception('Failed to update profile');
    return User.fromJson(data);
  }

  Future<void> changePassword(String currentPassword, String newPassword) async {
    await api.post('/employees/change-password', data: {
      'currentPassword': currentPassword,
      'newPassword': newPassword,
    });
  }

  Future<List<User>> getTeamMembers() async {
    final response = await api.get('/employees/manager/team');
    final data = response.data['data'];
    if (data == null) return [];
    final items = data as List<dynamic>;
    return items.map((e) => User.fromJson(e as Map<String, dynamic>)).toList();
  }
}
