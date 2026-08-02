import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_sizes.dart';
import '../../../core/constants/app_strings.dart';
import '../../../core/data/providers.dart';
import '../../../shared/widgets/custom_card.dart';
import '../../../shared/components/greeting_header.dart';

class CeoDashboard extends ConsumerStatefulWidget {
  const CeoDashboard({super.key});

  @override
  ConsumerState<CeoDashboard> createState() => _CeoDashboardState();
}

class _CeoDashboardState extends ConsumerState<CeoDashboard> {
  List<Map<String, dynamic>> _departmentRankings = [];
  Map<String, dynamic> _dashboardStats = {};
  Map<String, dynamic> _insights = {};
  bool _isLoading = true;
  String _userName = '';
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
      }

      final results = await Future.wait([
        ref.read(analyticsRepositoryProvider).getDashboardStats().catchError((_) => <String, dynamic>{}),
        ref.read(analyticsRepositoryProvider).getDepartmentRankings().catchError((_) => <Map<String, dynamic>>[]),
        ref.read(analyticsRepositoryProvider).getInsights().catchError((_) => <String, dynamic>{}),
        ref.read(notificationRepositoryProvider).getUnreadCount().catchError((_) => 0),
      ]);

      if (mounted) {
        setState(() {
          _dashboardStats = results[0] as Map<String, dynamic>;
          _departmentRankings = results[1] as List<Map<String, dynamic>>;
          _insights = results[2] as Map<String, dynamic>;
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
                subtitle: 'Chief Executive Officer',
                notificationCount: _notificationCount,
                onNotificationTap: () => context.push('/notifications'),
              ).animate().fadeIn(duration: 600.ms),

              const SizedBox(height: 20),

              _CompanyKPIs(dashboardStats: _dashboardStats)
                  .animate().fadeIn(delay: 200.ms, duration: 600.ms),

              const SizedBox(height: 16),

              _DepartmentRankings(departmentRankings: _departmentRankings)
                  .animate().fadeIn(delay: 400.ms, duration: 600.ms),

              const SizedBox(height: 16),

              _PredictiveInsights(insights: _insights)
                  .animate().fadeIn(delay: 600.ms, duration: 600.ms),
            ],
          ),
        ),
      ),
    );
  }
}

class _CompanyKPIs extends StatelessWidget {
  final Map<String, dynamic> dashboardStats;

  const _CompanyKPIs({required this.dashboardStats});

  @override
  Widget build(BuildContext context) {
    final totalEmployees = dashboardStats['totalEmployees'] ?? 0;
    final pendingApprovals = dashboardStats['pendingApprovals'] ?? 0;
    final leaveStats = dashboardStats['leaveStats'] as Map<String, dynamic>? ?? {};
    final todayAttendance = dashboardStats['todayAttendance'] as Map<String, dynamic>? ?? {};
    final presentCount = todayAttendance['present'] ?? 0;
    final attendanceRate = totalEmployees > 0 ? (presentCount / totalEmployees * 100).toInt() : 0;

    return Row(
      children: [
        Expanded(
          child: _KPICard(
            title: 'Total Employees',
            value: '$totalEmployees',
            icon: Icons.groups_rounded,
            color: AppColors.primary,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _KPICard(
            title: 'Attendance Rate',
            value: '$attendanceRate%',
            icon: Icons.access_time_rounded,
            color: AppColors.success,
          ),
        ),
      ],
    );
  }
}

class _KPICard extends StatelessWidget {
  final String title;
  final String value;
  final IconData icon;
  final Color color;

  const _KPICard({
    required this.title,
    required this.value,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return CustomCard(
      padding: AppSizes.p16,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(AppSizes.r8),
            ),
            child: Icon(icon, size: 20, color: color),
          ),
          const SizedBox(height: 12),
          Text(
            value,
            style: GoogleFonts.inter(
              fontSize: AppSizes.s28,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            title,
            style: GoogleFonts.inter(
              fontSize: AppSizes.s13,
              color: AppColors.grey500,
            ),
          ),
        ],
      ),
    );
  }
}

class _DepartmentRankings extends StatelessWidget {
  final List<Map<String, dynamic>> departmentRankings;

  const _DepartmentRankings({required this.departmentRankings});

  @override
  Widget build(BuildContext context) {
    return CustomCard(
      padding: AppSizes.p20,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            AppStrings.departmentRankings,
            style: GoogleFonts.inter(
              fontSize: AppSizes.s18,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 16),
          if (departmentRankings.isEmpty)
            Text(
              'No department data available',
              style: GoogleFonts.inter(
                fontSize: AppSizes.s14,
                color: AppColors.grey400,
              ),
            )
          else
            ...departmentRankings.asMap().entries.map((entry) {
              final dept = entry.value;
              final rank = entry.key + 1;
              final name = dept['name'] ?? dept['department'] ?? 'Unknown';
              final avgScore = (dept['averageScore'] as num?)?.toDouble() ?? 0;
              final employeeCount = dept['employeeCount'] ?? 0;

              return Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: Row(
                  children: [
                    Container(
                      width: 28,
                      height: 28,
                      decoration: BoxDecoration(
                        color: rank <= 3
                            ? [AppColors.primary, AppColors.accent, AppColors.warning][rank - 1].withValues(alpha: 0.1)
                            : AppColors.grey100,
                        shape: BoxShape.circle,
                      ),
                      child: Center(
                        child: Text(
                          '$rank',
                          style: GoogleFonts.inter(
                            fontSize: AppSizes.s12,
                            fontWeight: FontWeight.bold,
                            color: rank <= 3
                                ? [AppColors.primary, AppColors.accent, AppColors.warning][rank - 1]
                                : AppColors.grey500,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            '$name',
                            style: GoogleFonts.inter(
                              fontSize: AppSizes.s14,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          Text(
                            '$employeeCount employees',
                            style: GoogleFonts.inter(
                              fontSize: AppSizes.s12,
                              color: AppColors.grey400,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Text(
                      '${avgScore.toInt()}%',
                      style: GoogleFonts.inter(
                        fontSize: AppSizes.s16,
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

class _PredictiveInsights extends StatelessWidget {
  final Map<String, dynamic> insights;

  const _PredictiveInsights({required this.insights});

  @override
  Widget build(BuildContext context) {
    final topDepartments = insights['topDepartments'] as List<dynamic>? ?? [];
    final bottomDepartments = insights['bottomDepartments'] as List<dynamic>? ?? [];
    final pendingActions = insights['pendingActions'] ?? 0;
    final absenteeismRate = (insights['absenteeismRate'] as num?)?.toDouble() ?? 0;

    return CustomCard(
      padding: AppSizes.p20,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.auto_awesome_rounded, size: 20, color: AppColors.primary),
              const SizedBox(width: 8),
              Text(
                AppStrings.predictiveInsights,
                style: GoogleFonts.inter(
                  fontSize: AppSizes.s18,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          if (topDepartments.isNotEmpty)
            _InsightCard(
              icon: Icons.star_rounded,
              title: 'Top Performing Department',
              description: '${topDepartments.first['name']} leads with an average score of ${((topDepartments.first['averageScore'] as num?)?.toDouble() ?? 0).toInt()}%.',
              color: AppColors.success,
            ),
          const SizedBox(height: 12),
          if (pendingActions > 0)
            _InsightCard(
              icon: Icons.warning_amber_rounded,
              title: 'Pending Actions',
              description: 'There are $pendingActions pending approvals requiring attention.',
              color: AppColors.warning,
            ),
          const SizedBox(height: 12),
          _InsightCard(
            icon: Icons.trending_up_rounded,
            title: 'Absenteeism Rate',
            description: 'Current 30-day absenteeism rate is ${absenteeismRate.toStringAsFixed(1)}%.',
            color: absenteeismRate > 10 ? AppColors.error : AppColors.info,
          ),
        ],
      ),
    );
  }
}

class _InsightCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String description;
  final Color color;

  const _InsightCard({
    required this.icon,
    required this.title,
    required this.description,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(AppSizes.r12),
        border: Border.all(color: color.withValues(alpha: 0.15)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, size: 16, color: color),
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
                const SizedBox(height: 4),
                Text(
                  description,
                  style: GoogleFonts.inter(
                    fontSize: AppSizes.s12,
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
