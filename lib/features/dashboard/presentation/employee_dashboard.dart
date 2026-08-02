import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:percent_indicator/circular_percent_indicator.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_sizes.dart';
import '../../../core/constants/app_strings.dart';
import '../../../core/data/models/leave.dart';
import '../../../core/data/models/performance.dart';
import '../../../core/data/providers.dart';
import '../../../shared/widgets/custom_card.dart';
import '../../../shared/components/greeting_header.dart';

class EmployeeDashboard extends ConsumerStatefulWidget {
  const EmployeeDashboard({super.key});

  @override
  ConsumerState<EmployeeDashboard> createState() => _EmployeeDashboardState();
}

class _EmployeeDashboardState extends ConsumerState<EmployeeDashboard> {
  double _performanceScore = 0;
  Map<String, dynamic> _attendanceStats = {};
  List<LeaveBalance> _leaveBalances = [];
  bool _isLoading = true;
  int _notificationCount = 0;
  String _userName = '';
  String _position = '';
  String _department = '';

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    try {
      final authRepo = ref.read(authRepositoryProvider);
      final user = authRepo.currentUser;

      if (user != null) {
        _userName = user.name;
        _position = user.position;
        _department = user.department;
      }

      final results = await Future.wait([
        ref.read(performanceRepositoryProvider).getMyScore().catchError((_) => null),
        ref.read(attendanceRepositoryProvider).getAttendanceStats().catchError((_) => <String, dynamic>{}),
        ref.read(leaveRepositoryProvider).getLeaveBalance().catchError((_) => <LeaveBalance>[]),
        ref.read(notificationRepositoryProvider).getUnreadCount().catchError((_) => 0),
      ]);

      if (mounted) {
        setState(() {
          final perfScore = results[0] as PerformanceData?;
          if (perfScore != null) {
            _performanceScore = perfScore.overallScore;
          }
          _attendanceStats = results[1] as Map<String, dynamic>;
          _leaveBalances = results[2] as List<LeaveBalance>;
          _notificationCount = results[3] as int;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const SafeArea(
        child: Center(child: CircularProgressIndicator()),
      );
    }

    return SafeArea(
      child: RefreshIndicator(
        onRefresh: () async {
          setState(() => _isLoading = true);
          await _loadData();
        },
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(AppSizes.p16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              GreetingHeader(
                userName: _userName,
                subtitle: '$_position • $_department',
                notificationCount: _notificationCount,
                onNotificationTap: () => context.push('/notifications'),
              ).animate().fadeIn(duration: 600.ms).slideY(begin: -0.1, end: 0),

              const SizedBox(height: 20),

              _PerformanceScoreCard(
                score: _performanceScore,
              ).animate().fadeIn(delay: 200.ms, duration: 600.ms),

              const SizedBox(height: 16),

              Row(
                children: [
                  Expanded(
                    child: _AttendanceCard(data: _attendanceStats),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _LeaveBalanceCard(balances: _leaveBalances),
                  ),
                ],
              )
                  .animate()
                  .fadeIn(delay: 400.ms, duration: 600.ms)
                  .slideX(begin: -0.05, end: 0),

              const SizedBox(height: 16),

              _QuickActions()
                  .animate()
                  .fadeIn(delay: 600.ms, duration: 600.ms),

              const SizedBox(height: 16),

              _RecentActivities()
                  .animate()
                  .fadeIn(delay: 800.ms, duration: 600.ms),
            ],
          ),
        ),
      ),
    );
  }
}

class _PerformanceScoreCard extends StatelessWidget {
  final double score;

  const _PerformanceScoreCard({required this.score});

  @override
  Widget build(BuildContext context) {
    return CustomCard(
      padding: AppSizes.p24,
      child: Row(
        children: [
          CircularPercentIndicator(
            radius: 55,
            lineWidth: 10,
            percent: (score / 100).clamp(0.0, 1.0),
            center: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  '${score.toInt()}%',
                  style: GoogleFonts.inter(
                    fontSize: AppSizes.s24,
                    fontWeight: FontWeight.bold,
                    color: AppColors.primary,
                  ),
                ),
                Text(
                  'Score',
                  style: GoogleFonts.inter(
                    fontSize: AppSizes.s10,
                    color: AppColors.grey500,
                  ),
                ),
              ],
            ),
            progressColor: AppColors.primary,
            backgroundColor: AppColors.primarySurface,
            circularStrokeCap: CircularStrokeCap.round,
            animation: true,
            animationDuration: 1500,
          ),

          const SizedBox(width: 24),

          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  AppStrings.performanceScore,
                  style: GoogleFonts.inter(
                    fontSize: AppSizes.s18,
                    fontWeight: FontWeight.w600,
                    color: Theme.of(context).textTheme.bodyLarge?.color,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  score >= 80
                      ? 'Excellent performance! Keep up the great work.'
                      : score >= 60
                          ? 'Good performance. Keep improving!'
                          : 'Room for improvement. Let\'s work on this.',
                  style: GoogleFonts.inter(
                    fontSize: AppSizes.s13,
                    color: AppColors.grey500,
                    height: 1.4,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _AttendanceCard extends StatelessWidget {
  final Map<String, dynamic> data;

  const _AttendanceCard({required this.data});

  @override
  Widget build(BuildContext context) {
    final present = data['present'] ?? 0;
    final absent = data['absent'] ?? 0;
    final late = data['late'] ?? 0;

    return CustomCard(
      padding: AppSizes.p16,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppColors.success.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(AppSizes.r8),
                ),
                child: const Icon(
                  Icons.access_time_rounded,
                  size: 20,
                  color: AppColors.success,
                ),
              ),
              const SizedBox(width: 8),
              Text(
                AppStrings.attendance,
                style: GoogleFonts.inter(
                  fontSize: AppSizes.s14,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          _AttendanceRow(label: 'Present', count: present, color: AppColors.present),
          const SizedBox(height: 8),
          _AttendanceRow(label: 'Absent', count: absent, color: AppColors.absent),
          const SizedBox(height: 8),
          _AttendanceRow(label: 'Late', count: late, color: AppColors.late),
        ],
      ),
    );
  }
}

class _AttendanceRow extends StatelessWidget {
  final String label;
  final int count;
  final Color color;

  const _AttendanceRow({
    required this.label,
    required this.count,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Row(
          children: [
            Container(
              width: 8,
              height: 8,
              decoration: BoxDecoration(
                color: color,
                shape: BoxShape.circle,
              ),
            ),
            const SizedBox(width: 8),
            Text(
              label,
              style: GoogleFonts.inter(
                fontSize: AppSizes.s13,
                color: AppColors.grey500,
              ),
            ),
          ],
        ),
        Text(
          '$count days',
          style: GoogleFonts.inter(
            fontSize: AppSizes.s13,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }
}

class _LeaveBalanceCard extends StatelessWidget {
  final List<LeaveBalance> balances;

  const _LeaveBalanceCard({required this.balances});

  @override
  Widget build(BuildContext context) {
    return CustomCard(
      padding: AppSizes.p16,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppColors.info.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(AppSizes.r8),
                ),
                child: const Icon(
                  Icons.event_busy_rounded,
                  size: 20,
                  color: AppColors.info,
                ),
              ),
              const SizedBox(width: 8),
              Text(
                AppStrings.leaveBalance,
                style: GoogleFonts.inter(
                  fontSize: AppSizes.s14,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          ...balances.map((balance) {
            return Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    balance.typeName,
                    style: GoogleFonts.inter(
                      fontSize: AppSizes.s13,
                      color: AppColors.grey500,
                    ),
                  ),
                  Text(
                    '${balance.remainingDays} ${AppStrings.days}',
                    style: GoogleFonts.inter(
                      fontSize: AppSizes.s13,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            );
          }),
          if (balances.isEmpty)
            Text(
              'No leave balances found',
              style: GoogleFonts.inter(
                fontSize: AppSizes.s13,
                color: AppColors.grey400,
              ),
            ),
        ],
      ),
    );
  }
}

class _QuickActions extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          AppStrings.quickActions,
          style: GoogleFonts.inter(
            fontSize: AppSizes.s18,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 12),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            _QuickActionButton(
              icon: Icons.add_circle_outline_rounded,
              label: AppStrings.requestLeave,
              onTap: () => context.push('/leave-request'),
              color: AppColors.primary,
            ),
            _QuickActionButton(
              icon: Icons.how_to_reg_rounded,
              label: AppStrings.markAttendance,
              onTap: () {},
              color: AppColors.info,
            ),
            _QuickActionButton(
              icon: Icons.bar_chart_rounded,
              label: AppStrings.reports,
              onTap: () {},
              color: AppColors.warning,
            ),
            _QuickActionButton(
              icon: Icons.calendar_month_rounded,
              label: AppStrings.teamCalendar,
              onTap: () => context.push('/team-availability'),
              color: AppColors.accent,
            ),
          ],
        ),
      ],
    );
  }
}

class _QuickActionButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final Color color;

  const _QuickActionButton({
    required this.icon,
    required this.label,
    required this.onTap,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: SizedBox(
        width: 76,
        child: Column(
          children: [
            Container(
              width: AppSizes.quickActionSize,
              height: AppSizes.quickActionSize,
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(AppSizes.r16),
              ),
              child: Icon(icon, size: 28, color: color),
            ),
            const SizedBox(height: 8),
            Text(
              label,
              style: GoogleFonts.inter(
                fontSize: AppSizes.s11,
                color: AppColors.grey600,
                fontWeight: FontWeight.w500,
              ),
              textAlign: TextAlign.center,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }
}

class _RecentActivities extends ConsumerStatefulWidget {
  @override
  ConsumerState<_RecentActivities> createState() => _RecentActivitiesState();
}

class _RecentActivitiesState extends ConsumerState<_RecentActivities> {
  List<dynamic> _notifications = [];
  List<dynamic> _records = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    try {
      final results = await Future.wait([
        ref.read(notificationRepositoryProvider).getNotifications().catchError((_) => <dynamic>[]),
        ref.read(attendanceRepositoryProvider).getMyRecords(page: 1, limit: 3).catchError((_) => <dynamic>[]),
      ]);
      if (mounted) {
        setState(() {
          _notifications = results[0] as List<dynamic>;
          _records = results[1] as List<dynamic>;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          AppStrings.recentActivities,
          style: GoogleFonts.inter(
            fontSize: AppSizes.s18,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 12),
        if (_isLoading)
          CustomCard(
            padding: AppSizes.p16,
            child: const Center(child: CircularProgressIndicator()),
          )
        else if (_notifications.isEmpty && _records.isEmpty)
          CustomCard(
            padding: AppSizes.p16,
            child: Text(
              'No recent activities',
              style: GoogleFonts.inter(
                fontSize: AppSizes.s14,
                color: AppColors.grey400,
              ),
            ),
          )
        else
          CustomCard(
            padding: AppSizes.p16,
            child: Column(
              children: [
                ..._records.take(2).map((record) {
                  return Column(
                    children: [
                      _ActivityTile(
                        icon: Icons.check_circle_rounded,
                        title: 'Attendance marked',
                        subtitle: 'Status: ${record.status}',
                        time: '${record.date}',
                        color: AppColors.success,
                      ),
                      const Divider(height: 24),
                    ],
                  );
                }),
                ..._notifications.take(2).map((notif) {
                  return Column(
                    children: [
                      _ActivityTile(
                        icon: _getNotificationIcon(notif.type.name),
                        title: notif.title,
                        subtitle: notif.message,
                        time: '${notif.timestamp}',
                        color: _getNotificationColor(notif.type.name),
                      ),
                      const Divider(height: 24),
                    ],
                  );
                }),
              ],
            ),
          ),
      ],
    );
  }

  IconData _getNotificationIcon(String type) {
    switch (type.toUpperCase()) {
      case 'LEAVE':
        return Icons.event_available_rounded;
      case 'PERFORMANCE':
        return Icons.trending_up_rounded;
      case 'ATTENDANCE':
        return Icons.access_time_rounded;
      case 'CHAT':
        return Icons.chat_bubble_rounded;
      default:
        return Icons.notifications_rounded;
    }
  }

  Color _getNotificationColor(String type) {
    switch (type.toUpperCase()) {
      case 'LEAVE':
        return AppColors.primary;
      case 'PERFORMANCE':
        return AppColors.info;
      case 'ATTENDANCE':
        return AppColors.success;
      case 'CHAT':
        return AppColors.accent;
      default:
        return AppColors.grey500;
    }
  }
}

class _ActivityTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final String time;
  final Color color;

  const _ActivityTile({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.time,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(AppSizes.r10),
          ),
          child: Icon(icon, size: 20, color: color),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: GoogleFonts.inter(
                  fontSize: AppSizes.s14,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                subtitle,
                style: GoogleFonts.inter(
                  fontSize: AppSizes.s12,
                  color: AppColors.grey500,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
        Text(
          time,
          style: GoogleFonts.inter(
            fontSize: AppSizes.s11,
            color: AppColors.grey400,
          ),
        ),
      ],
    );
  }
}
