import '../datasources/api_service.dart';
import '../models/notification.dart';

class NotificationRepository {
  final ApiService api;

  NotificationRepository({required this.api});

  Future<List<AppNotification>> getNotifications({bool unreadOnly = false}) async {
    final params = <String, dynamic>{};
    if (unreadOnly) params['unreadOnly'] = 'true';

    final response = await api.get('/notifications', queryParameters: params);
    final data = response.data['data'];
    if (data == null) return [];
    final items = data as List<dynamic>;
    return items.map((e) => AppNotification.fromJson(e as Map<String, dynamic>)).toList();
  }

  Future<int> getUnreadCount() async {
    final response = await api.get('/notifications/unread-count');
    return response.data['data'] ?? 0;
  }

  Future<AppNotification> markAsRead(String id) async {
    final response = await api.patch('/notifications/$id/read');
    final data = response.data['data'];
    if (data == null) throw Exception('Failed to mark as read');
    return AppNotification.fromJson(data);
  }

  Future<void> markAllAsRead() async {
    await api.patch('/notifications/read-all');
  }
}
