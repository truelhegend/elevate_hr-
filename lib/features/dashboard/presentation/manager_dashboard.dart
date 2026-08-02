import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_sizes.dart';
import '../../../core/constants/app_strings.dart';
import '../../../core/data/models/leave.dart';
import '../../../core/data/providers.dart';
import '../../../core/utils/helpers.dart';
import '../../../shared/widgets/custom_card.dart';
import '../../../shared/components/greeting_header.dart';

class ManagerDashboard extends ConsumerStatefulWidget {
  const ManagerDashboard({super.key});

  @override
  ConsumerState<ManagerDashboard> createState() => _ManagerDashboardState();
}

class _ManagerDashboardState extends ConsumerState<ManagerDashboard> {
  List<Map<String, dynamic>> _teamPerformance = [];
  List<LeaveRequest> _pendingLeaves = [];
  List<Map<String, dynamic>> _teamAvailability = [];
  Map<String, dynamic> _dashboardStats = {};
  bool _isLoading = true;
  String _userName = '';
  String _position = '';
  int _notificationCount = 0;

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
      }

      final results = await Future.wait([
        ref.read(performanceRepositoryProvider).getTeamPerformance().catchError((_) => <Map<String, dynamic>>[]),
        ref.read(leaveRepositoryProvider).getPendingApprovals().catchError((_) => <LeaveRequest>[]),
        ref.read(attendanceRepositoryProvider).getTeamAvailability().catchError((_) => <Map<String, dynamic>>[]),
        ref.read(analyticsRepositoryProvider).getDashboardStats().catchError((_) => <String, dynamic>{}),
        ref.read(notificationRepositoryProvider).getUnreadCount().catchError((_) => 0),
      ]);

      if (mounted) {
        setState(() {
          _teamPerformance = results[0] as List<Map<String, dynamic>>;
          _pendingLeaves = results[1] as List<LeaveRequest>;
          _teamAvailability = results[2] as List<Map<String, dynamic>>;
          _dashboardStats = results[3] as Map<String, dynamic>;
          _notificationCount = results[4] as int;
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

    final presentCount = _teamAvailability.where((m) => m['status'] == 'PRESENT' || m['status'] == 'LATE').length;
    final remoteCount = _teamAvailability.where((m) => m['status'] == 'REMOTE').length;
    final onLeaveCount = _teamAvailability.where((m) => m['status'] == 'ON_LEAVE' || m['status'] == 'ABSENT').length;

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
                subtitle: _position,
                notificationCount: _notificationCount,
                onNotificationTap: () => context.push('/notifications'),
              ).animate().fadeIn(duration: 600.ms),

              const SizedBox(height: 20),

              _TeamPerformanceSummary(teamPerformance: _teamPerformance)
                  .animate().fadeIn(delay: 200.ms, duration: 600.ms),

              const SizedBox(height: 16),

              _PendingLeaveRequests(
                pendingLeaves: _pendingLeaves,
                onRefresh: () => _loadData(),
                onApprove: (id, {String? comment}) async {
                  await ref.read(leaveRepositoryProvider).approveLeave(id, comment: comment);
                },
                onReject: (id, {String? comment}) async {
                  await ref.read(leaveRepositoryProvider).rejectLeave(id, comment: comment);
                },
              )
                  .animate().fadeIn(delay: 400.ms, duration: 600.ms),

              const SizedBox(height: 16),

              _TeamAvailabilityWidget(
                presentCount: presentCount,
                remoteCount: remoteCount,
                onLeaveCount: onLeaveCount,
              )
                  .animate().fadeIn(delay: 600.ms, duration: 600.ms),

              const SizedBox(height: 16),

              _DepartmentSummary(dashboardStats: _dashboardStats)
                  .animate().fadeIn(delay: 800.ms, duration: 600.ms),
            ],
          ),
        ),
      ),
    );
  }
}

class _TeamPerformanceSummary extends StatelessWidget {
  final List<Map<String, dynamic>> teamPerformance;

  const _TeamPerformanceSummary({required this.teamPerformance});

  @override
  Widget build(BuildContext context) {
    final avgScore = teamPerformance.isNotEmpty
        ? teamPerformance.map((e) => (e['currentScore'] as num?)?.toDouble() ?? 0).reduce((a, b) => a + b) / teamPerformance.length
        : 0.0;

    return CustomCard(
      padding: AppSizes.p20,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                AppStrings.teamPerformance,
                style: GoogleFonts.inter(
                  fontSize: AppSizes.s18,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          Row(
            children: [
              _TeamMetric(
                label: 'Avg Score',
                value: '${avgScore.toInt()}%',
                color: AppColors.primary,
              ),
              const SizedBox(width: 16),
              _TeamMetric(
                label: 'Team Size',
                value: '${teamPerformance.length}',
                color: AppColors.info,
              ),
              const SizedBox(width: 16),
              _TeamMetric(
                label: 'On Track',
                value: '${teamPerformance.where((e) => ((e['currentScore'] as num?)?.toDouble() ?? 0) >= 70).length}',
                color: AppColors.success,
              ),
            ],
          ),
          const SizedBox(height: 16),
          ...teamPerformance.take(3).map((member) {
            final name = '${member['firstName'] ?? ''} ${member['lastName'] ?? ''}'.trim();
            final score = (member['currentScore'] as num?)?.toDouble() ?? 0;
            return Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Row(
                children: [
                  CircleAvatar(
                    radius: 16,
                    backgroundColor: AppHelpers.getStatusColor('present').withValues(alpha: 0.1),
                    child: Text(
                      name.split(' ').map((n) => n.isNotEmpty ? n[0] : '').join(),
                      style: GoogleFonts.inter(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: AppColors.primary,
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      name,
                      style: GoogleFonts.inter(
                        fontSize: AppSizes.s14,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                  Text(
                    '${score.toInt()}%',
                    style: GoogleFonts.inter(
                      fontSize: AppSizes.s14,
                      fontWeight: FontWeight.w600,
                      color: AppColors.primary,
                    ),
                  ),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }
}

class _TeamMetric extends StatelessWidget {
  final String label;
  final String value;
  final Color color;

  const _TeamMetric({
    required this.label,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.06),
          borderRadius: BorderRadius.circular(AppSizes.r12),
        ),
        child: Column(
          children: [
            Text(
              value,
              style: GoogleFonts.inter(
                fontSize: AppSizes.s20,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: GoogleFonts.inter(
                fontSize: AppSizes.s11,
                color: AppColors.grey500,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _PendingLeaveRequests extends StatefulWidget {
  final List<LeaveRequest> pendingLeaves;
  final VoidCallback onRefresh;
  final Future<void> Function(String id, {String? comment}) onApprove;
  final Future<void> Function(String id, {String? comment}) onReject;

  const _PendingLeaveRequests({
    required this.pendingLeaves,
    required this.onRefresh,
    required this.onApprove,
    required this.onReject,
  });

  @override
  State<_PendingLeaveRequests> createState() => _PendingLeaveRequestsState();
}

class _PendingLeaveRequestsState extends State<_PendingLeaveRequests> {
  final Set<String> _processingIds = {};

  @override
  Widget build(BuildContext context) {
    return CustomCard(
      padding: AppSizes.p20,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                AppStrings.pendingRequests,
                style: GoogleFonts.inter(
                  fontSize: AppSizes.s18,
                  fontWeight: FontWeight.w600,
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: AppColors.warning.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(AppSizes.rFull),
                ),
                child: Text(
                  '${widget.pendingLeaves.length}',
                  style: GoogleFonts.inter(
                    fontSize: AppSizes.s12,
                    fontWeight: FontWeight.w600,
                    color: AppColors.warning,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          if (widget.pendingLeaves.isEmpty)
            Text(
              'No pending requests',
              style: GoogleFonts.inter(
                fontSize: AppSizes.s14,
                color: AppColors.grey400,
              ),
            )
          else
            ...widget.pendingLeaves.take(3).map((request) {
              final isProcessing = _processingIds.contains(request.id);
              return Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: Row(
                  children: [
                    CircleAvatar(
                      radius: 20,
                      backgroundColor: AppColors.primarySurface,
                      child: Text(
                        request.userName.split(' ').map((n) => n.isNotEmpty ? n[0] : '').join(),
                        style: GoogleFonts.inter(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: AppColors.primary,
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            request.userName,
                            style: GoogleFonts.inter(
                              fontSize: AppSizes.s14,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          Text(
                            '${request.typeName} • ${request.totalDays} ${AppStrings.days}',
                            style: GoogleFonts.inter(
                              fontSize: AppSizes.s12,
                              color: AppColors.grey500,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Row(
                      children: [
                        _ActionButton(
                          icon: isProcessing ? Icons.hourglass_top_rounded : Icons.check_rounded,
                          color: AppColors.success,
                          onTap: isProcessing
                              ? null
                              : () async {
                                  setState(() => _processingIds.add(request.id));
                                  await widget.onApprove(request.id);
                                  if (mounted) {
                                    setState(() => _processingIds.remove(request.id));
                                    widget.onRefresh();
                                  }
                                },
                        ),
                        const SizedBox(width: 8),
                        _ActionButton(
                          icon: isProcessing ? Icons.hourglass_top_rounded : Icons.close_rounded,
                          color: AppColors.error,
                          onTap: isProcessing
                              ? null
                              : () async {
                                  setState(() => _processingIds.add(request.id));
                                  await widget.onReject(request.id);
                                  if (mounted) {
                                    setState(() => _processingIds.remove(request.id));
                                    widget.onRefresh();
                                  }
                                },
                        ),
                      ],
                    ),
                  ],
                ),
              );
            }),
        ],
      ),
    );
  }
}

class _ActionButton extends StatelessWidget {
  final IconData icon;
  final Color color;
  final VoidCallback? onTap;

  const _ActionButton({
    required this.icon,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 36,
        height: 36,
        decoration: BoxDecoration(
          color: (onTap != null ? color : AppColors.grey400).withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(AppSizes.r8),
        ),
        child: Icon(icon, size: 18, color: onTap != null ? color : AppColors.grey400),
      ),
    );
  }
}

class _TeamAvailabilityWidget extends StatelessWidget {
  final int presentCount;
  final int remoteCount;
  final int onLeaveCount;

  const _TeamAvailabilityWidget({
    required this.presentCount,
    required this.remoteCount,
    required this.onLeaveCount,
  });

  @override
  Widget build(BuildContext context) {
    return CustomCard(
      padding: AppSizes.p20,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Team Availability',
                style: GoogleFonts.inter(
                  fontSize: AppSizes.s18,
                  fontWeight: FontWeight.w600,
                ),
              ),
              TextButton(
                onPressed: () => context.push('/team-availability'),
                child: Text(
                  'View All',
                  style: GoogleFonts.inter(
                    fontSize: AppSizes.s13,
                    color: AppColors.primary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              _AvailabilityChip(label: 'Present', count: presentCount, color: AppColors.present),
              const SizedBox(width: 8),
              _AvailabilityChip(label: 'Remote', count: remoteCount, color: AppColors.remote),
              const SizedBox(width: 8),
              _AvailabilityChip(label: 'On Leave', count: onLeaveCount, color: AppColors.onLeave),
            ],
          ),
        ],
      ),
    );
  }
}

class _AvailabilityChip extends StatelessWidget {
  final String label;
  final int count;
  final Color color;

  const _AvailabilityChip({
    required this.label,
    required this.count,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 10),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(AppSizes.r8),
        ),
        child: Column(
          children: [
            Text(
              '$count',
              style: GoogleFonts.inter(
                fontSize: AppSizes.s18,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
            Text(
              label,
              style: GoogleFonts.inter(
                fontSize: AppSizes.s11,
                color: color,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _DepartmentSummary extends StatelessWidget {
  final Map<String, dynamic> dashboardStats;

  const _DepartmentSummary({required this.dashboardStats});

  @override
  Widget build(BuildContext context) {
    final pendingApprovals = dashboardStats['pendingApprovals'] ?? 0;
    final totalEmployees = dashboardStats['totalEmployees'] ?? 0;
    final departmentCount = dashboardStats['departmentCount'] ?? 0;

    return CustomCard(
      padding: AppSizes.p20,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            AppStrings.departmentSummary,
            style: GoogleFonts.inter(
              fontSize: AppSizes.s18,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 16),
          _StatRow(label: 'Total Employees', value: '$totalEmployees'),
          const SizedBox(height: 12),
          _StatRow(label: 'Departments', value: '$departmentCount'),
          const SizedBox(height: 12),
          _StatRow(label: 'Pending Approvals', value: '$pendingApprovals'),
        ],
      ),
    );
  }
}

class _StatRow extends StatelessWidget {
  final String label;
  final String value;

  const _StatRow({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: GoogleFonts.inter(
            fontSize: AppSizes.s14,
            color: AppColors.grey500,
          ),
        ),
        Text(
          value,
          style: GoogleFonts.inter(
            fontSize: AppSizes.s14,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }
}
