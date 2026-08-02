import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_sizes.dart';
import '../../../core/data/models/notification.dart' as models;
import '../../../core/data/providers.dart';
import '../../../core/utils/extensions.dart';

class NotificationsScreen extends ConsumerStatefulWidget {
  const NotificationsScreen({super.key});

  @override
  ConsumerState<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends ConsumerState<NotificationsScreen> {
  List<models.AppNotification> _notifications = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    try {
      final notifications = await ref.read(notificationRepositoryProvider).getNotifications();
      if (mounted) {
        setState(() {
          _notifications = notifications;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  void _markAllRead() async {
    try {
      await ref.read(notificationRepositoryProvider).markAllAsRead();
      setState(() {
        _notifications = _notifications.map((n) => n.copyWith(isRead: true)).toList();
      });
    } catch (_) {}
  }

  void _markAsRead(String notificationId) async {
    try {
      await ref.read(notificationRepositoryProvider).markAsRead(notificationId);
      setState(() {
        final index = _notifications.indexWhere((n) => n.id == notificationId);
        if (index != -1) {
          _notifications[index] = _notifications[index].copyWith(isRead: true);
        }
      });
    } catch (_) {}
  }

  IconData _getNotificationIcon(models.NotificationType type) {
    switch (type) {
      case models.NotificationType.leave:
        return Icons.event_available_rounded;
      case models.NotificationType.attendance:
        return Icons.access_time_rounded;
      case models.NotificationType.performance:
        return Icons.insights_rounded;
      case models.NotificationType.system:
        return Icons.info_outline_rounded;
      case models.NotificationType.chat:
        return Icons.chat_bubble_outline_rounded;
      case models.NotificationType.info:
        return Icons.notifications_none_rounded;
    }
  }

  Color _getNotificationColor(models.NotificationType type) {
    switch (type) {
      case models.NotificationType.leave:
        return AppColors.primary;
      case models.NotificationType.attendance:
        return AppColors.info;
      case models.NotificationType.performance:
        return AppColors.success;
      case models.NotificationType.system:
        return AppColors.grey500;
      case models.NotificationType.chat:
        return AppColors.accent;
      case models.NotificationType.info:
        return AppColors.info;
    }
  }

  @override
  Widget build(BuildContext context) {
    final unreadCount = _notifications.where((n) => !n.isRead).length;

    if (_isLoading) {
      return Scaffold(
        appBar: AppBar(title: const Text('Notifications')),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Notifications'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_rounded),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          if (unreadCount > 0)
            TextButton(
              onPressed: _markAllRead,
              child: Text(
                'Mark all read',
                style: GoogleFonts.inter(
                  fontSize: AppSizes.s13,
                  color: AppColors.primary,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
        ],
      ),
      body: _notifications.isEmpty
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    width: 96,
                    height: 96,
                    decoration: const BoxDecoration(
                      color: AppColors.primarySurface,
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.notifications_none_rounded,
                      size: 48,
                      color: AppColors.primary,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'No notifications',
                    style: GoogleFonts.inter(
                      fontSize: AppSizes.s18,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'You\'re all caught up!',
                    style: GoogleFonts.inter(
                      fontSize: AppSizes.s14,
                      color: AppColors.grey500,
                    ),
                  ),
                ],
              ),
            )
          : RefreshIndicator(
              onRefresh: () async {
                setState(() => _isLoading = true);
                await _loadData();
              },
              child: ListView.builder(
                padding: const EdgeInsets.all(AppSizes.p16),
                itemCount: _notifications.length,
                itemBuilder: (context, index) {
                  final notification = _notifications[index];
                  final color = _getNotificationColor(notification.type);
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: GestureDetector(
                      onTap: () => _markAsRead(notification.id),
                      child: Container(
                        padding: const EdgeInsets.all(AppSizes.p16),
                        decoration: BoxDecoration(
                          color: notification.isRead
                              ? Theme.of(context).cardColor
                              : color.withValues(alpha: 0.03),
                          borderRadius: BorderRadius.circular(AppSizes.r16),
                          border: Border.all(
                            color: notification.isRead
                                ? AppColors.grey200
                                : color.withValues(alpha: 0.2),
                          ),
                        ),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Container(
                              width: 44,
                              height: 44,
                              decoration: BoxDecoration(
                                color: color.withValues(alpha: 0.1),
                                borderRadius: BorderRadius.circular(AppSizes.r12),
                              ),
                              child: Icon(
                                _getNotificationIcon(notification.type),
                                size: 22,
                                color: color,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      Expanded(
                                        child: Text(
                                          notification.title,
                                          style: GoogleFonts.inter(
                                            fontSize: AppSizes.s14,
                                            fontWeight: notification.isRead
                                                ? FontWeight.w500
                                                : FontWeight.w600,
                                          ),
                                        ),
                                      ),
                                      if (!notification.isRead)
                                        Container(
                                          width: 8,
                                          height: 8,
                                          decoration: const BoxDecoration(
                                            color: AppColors.primary,
                                            shape: BoxShape.circle,
                                          ),
                                        ),
                                    ],
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    notification.message,
                                    style: GoogleFonts.inter(
                                      fontSize: AppSizes.s13,
                                      color: AppColors.grey500,
                                      height: 1.4,
                                    ),
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                  const SizedBox(height: 8),
                                  Text(
                                    notification.timestamp.relativeDate,
                                    style: GoogleFonts.inter(
                                      fontSize: AppSizes.s11,
                                      color: AppColors.grey400,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    )
                        .animate()
                        .fadeIn(
                          delay: Duration(milliseconds: 80 * index),
                          duration: 500.ms,
                        )
                        .slideX(begin: 0.02, end: 0),
                  );
                },
              ),
            ),
    );
  }
}
