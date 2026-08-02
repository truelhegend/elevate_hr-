import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_sizes.dart';
import '../../../core/data/providers.dart';
import '../../../core/utils/helpers.dart';
import '../../../shared/widgets/custom_card.dart';
import '../../../shared/components/status_badge.dart';

class TeamAvailabilityScreen extends ConsumerStatefulWidget {
  const TeamAvailabilityScreen({super.key});

  @override
  ConsumerState<TeamAvailabilityScreen> createState() => _TeamAvailabilityScreenState();
}

class _TeamAvailabilityScreenState extends ConsumerState<TeamAvailabilityScreen> {
  String _selectedFilter = 'All';
  final List<String> _filters = ['All', 'Present', 'Late', 'Remote', 'On Leave', 'Absent'];
  List<Map<String, dynamic>> _teamMembers = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    try {
      final members = await ref.read(attendanceRepositoryProvider).getTeamAvailability();
      if (mounted) {
        setState(() {
          _teamMembers = members;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  List<Map<String, dynamic>> get _filteredMembers {
    if (_selectedFilter == 'All') return _teamMembers;
    final statusMap = {
      'Present': 'PRESENT',
      'Late': 'LATE',
      'Remote': 'REMOTE',
      'On Leave': 'ON_LEAVE',
      'Absent': 'ABSENT',
    };
    final targetStatus = statusMap[_selectedFilter];
    return _teamMembers.where((m) => m['status'] == targetStatus).toList();
  }

  int _countByStatus(String status) {
    return _teamMembers.where((m) => m['status'] == status).length;
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
        appBar: AppBar(title: const Text('Team Availability')),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Team Availability'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_rounded),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(AppSizes.p16),
            child: Row(
              children: [
                _SummaryChip(label: 'Present', count: _countByStatus('PRESENT'), color: AppColors.present),
                const SizedBox(width: 8),
                _SummaryChip(label: 'Late', count: _countByStatus('LATE'), color: AppColors.late),
                const SizedBox(width: 8),
                _SummaryChip(label: 'Remote', count: _countByStatus('REMOTE'), color: AppColors.remote),
                const SizedBox(width: 8),
                _SummaryChip(label: 'On Leave', count: _countByStatus('ON_LEAVE'), color: AppColors.onLeave),
                const SizedBox(width: 8),
                _SummaryChip(label: 'Absent', count: _countByStatus('ABSENT'), color: AppColors.absent),
              ],
            ).animate().fadeIn(duration: 600.ms),
          ),

          SizedBox(
            height: 40,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: AppSizes.p16),
              itemCount: _filters.length,
              separatorBuilder: (_, __) => const SizedBox(width: 8),
              itemBuilder: (context, index) {
                final filter = _filters[index];
                final isSelected = _selectedFilter == filter;
                return GestureDetector(
                  onTap: () => setState(() => _selectedFilter = filter),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    decoration: BoxDecoration(
                      color: isSelected ? AppColors.primary : AppColors.grey100,
                      borderRadius: BorderRadius.circular(AppSizes.rFull),
                    ),
                    child: Center(
                      child: Text(
                        filter,
                        style: GoogleFonts.inter(
                          fontSize: AppSizes.s13,
                          fontWeight: FontWeight.w600,
                          color: isSelected ? Colors.white : AppColors.grey600,
                        ),
                      ),
                    ),
                  ),
                );
              },
            ),
          )
              .animate()
              .fadeIn(delay: 200.ms, duration: 600.ms),

          const SizedBox(height: 16),

          Expanded(
            child: _filteredMembers.isEmpty
                ? Center(
                    child: Text(
                      'No team members found',
                      style: GoogleFonts.inter(
                        fontSize: AppSizes.s14,
                        color: AppColors.grey400,
                      ),
                    ),
                  )
                : ListView.builder(
                    padding: const EdgeInsets.symmetric(horizontal: AppSizes.p16),
                    itemCount: _filteredMembers.length,
                    itemBuilder: (context, index) {
                      final member = _filteredMembers[index];
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 12),
                        child: _TeamMemberCard(member: member)
                            .animate()
                            .fadeIn(
                              delay: Duration(milliseconds: 100 * index),
                              duration: 500.ms,
                            ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}

class _SummaryChip extends StatelessWidget {
  final String label;
  final int count;
  final Color color;

  const _SummaryChip({
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
          borderRadius: BorderRadius.circular(AppSizes.r10),
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
                fontSize: 10,
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

class _TeamMemberCard extends StatelessWidget {
  final Map<String, dynamic> member;

  const _TeamMemberCard({required this.member});

  @override
  Widget build(BuildContext context) {
    final firstName = member['firstName'] ?? '';
    final lastName = member['lastName'] ?? '';
    final name = '$firstName $lastName'.trim();
    final status = member['status'] ?? 'ABSENT';
    final clockIn = member['clockIn'];
    final clockOut = member['clockOut'];

    String statusDisplay;
    switch (status) {
      case 'PRESENT':
        statusDisplay = 'Present';
        break;
      case 'LATE':
        statusDisplay = 'Late';
        break;
      case 'REMOTE':
        statusDisplay = 'Remote';
        break;
      case 'ON_LEAVE':
        statusDisplay = 'On Leave';
        break;
      case 'ABSENT':
        statusDisplay = 'Absent';
        break;
      default:
        statusDisplay = status;
    }

    final statusColor = AppHelpers.getStatusColor(statusDisplay);

    return CustomCard(
      padding: AppSizes.p16,
      child: Row(
        children: [
          CircleAvatar(
            radius: 24,
            backgroundColor: statusColor.withValues(alpha: 0.1),
            child: Text(
              name.split(' ').map((n) => n.isNotEmpty ? n[0] : '').join(),
              style: GoogleFonts.inter(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: statusColor,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  name,
                  style: GoogleFonts.inter(
                    fontSize: AppSizes.s15,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 4),
                if (clockIn != null || clockOut != null)
                  Text(
                    'In: ${clockIn != null ? DateTime.tryParse(clockIn)?.toString().substring(11, 16) ?? '--:--' : '--:--'} • Out: ${clockOut != null ? DateTime.tryParse(clockOut)?.toString().substring(11, 16) ?? '--:--' : '--:--'}',
                    style: GoogleFonts.inter(
                      fontSize: AppSizes.s12,
                      color: AppColors.grey500,
                    ),
                  ),
              ],
            ),
          ),
          StatusBadge(status: statusDisplay),
        ],
      ),
    );
  }
}
