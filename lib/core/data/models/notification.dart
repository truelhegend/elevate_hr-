enum NotificationType { leave, attendance, performance, system, chat, info }

class AppNotification {
  final String id;
  final String title;
  final String message;
  final NotificationType type;
  final DateTime timestamp;
  final bool isRead;
  final String? actionRoute;
  final Map<String, dynamic>? data;

  const AppNotification({
    required this.id,
    required this.title,
    required this.message,
    required this.type,
    required this.timestamp,
    this.isRead = false,
    this.actionRoute,
    this.data,
  });

  AppNotification copyWith({
    String? id,
    String? title,
    String? message,
    NotificationType? type,
    DateTime? timestamp,
    bool? isRead,
    String? actionRoute,
    Map<String, dynamic>? data,
  }) {
    return AppNotification(
      id: id ?? this.id,
      title: title ?? this.title,
      message: message ?? this.message,
      type: type ?? this.type,
      timestamp: timestamp ?? this.timestamp,
      isRead: isRead ?? this.isRead,
      actionRoute: actionRoute ?? this.actionRoute,
      data: data ?? this.data,
    );
  }

  factory AppNotification.fromJson(Map<String, dynamic> json) {
    return AppNotification(
      id: json['id'] ?? '',
      title: json['title'] ?? '',
      message: json['message'] ?? '',
      type: _parseType(json['type']),
      timestamp: DateTime.tryParse(json['createdAt'] ?? '') ?? DateTime.now(),
      isRead: json['isRead'] ?? false,
      actionRoute: json['actionRoute'],
      data: json['data'] is Map ? Map<String, dynamic>.from(json['data']) : null,
    );
  }

  static NotificationType _parseType(dynamic value) {
    if (value == null) return NotificationType.system;
    switch (value.toString().toUpperCase()) {
      case 'LEAVE':
        return NotificationType.leave;
      case 'ATTENDANCE':
        return NotificationType.attendance;
      case 'PERFORMANCE':
        return NotificationType.performance;
      case 'CHAT':
        return NotificationType.chat;
      case 'INFO':
        return NotificationType.info;
      default:
        return NotificationType.system;
    }
  }

  static List<AppNotification> get demo => [
        AppNotification(
          id: 'N001',
          title: 'Leave Approved',
          message: 'Your annual leave request for Dec 20-23 has been approved by Michael Chen.',
          type: NotificationType.leave,
          timestamp: DateTime.now().subtract(const Duration(minutes: 30)),
        ),
        AppNotification(
          id: 'N002',
          title: 'Performance Review',
          message: 'Your quarterly performance review is ready. Tap to view your results.',
          type: NotificationType.performance,
          timestamp: DateTime.now().subtract(const Duration(hours: 2)),
        ),
        AppNotification(
          id: 'N003',
          title: 'Leave Request Pending',
          message: 'Alex Thompson has requested 3 days of annual leave. Review and take action.',
          type: NotificationType.leave,
          timestamp: DateTime.now().subtract(const Duration(hours: 5)),
          actionRoute: '/approvals',
        ),
        AppNotification(
          id: 'N004',
          title: 'Attendance Reminder',
          message: "Don't forget to clock in before 9:00 AM.",
          type: NotificationType.attendance,
          timestamp: DateTime.now().subtract(const Duration(hours: 8)),
        ),
        AppNotification(
          id: 'N005',
          title: 'New Message',
          message: 'Michael Chen sent you a message about the project deadline.',
          type: NotificationType.chat,
          timestamp: DateTime.now().subtract(const Duration(days: 1)),
        ),
        AppNotification(
          id: 'N006',
          title: 'System Update',
          message: 'Elevate HR has been updated to v1.0.0. Check out the new features!',
          type: NotificationType.system,
          timestamp: DateTime.now().subtract(const Duration(days: 2)),
          isRead: true,
        ),
      ];
}
