import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:percent_indicator/circular_percent_indicator.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_sizes.dart';
import '../../../core/data/models/performance.dart';
import '../../../core/data/providers.dart';
import '../../../shared/widgets/custom_card.dart';

class PerformanceScreen extends ConsumerStatefulWidget {
  const PerformanceScreen({super.key});

  @override
  ConsumerState<PerformanceScreen> createState() => _PerformanceScreenState();
}

class _PerformanceScreenState extends ConsumerState<PerformanceScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  PerformanceData? _performance;
  List<PerformanceTrend> _history = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _loadData();
  }

  Future<void> _loadData() async {
    try {
      final results = await Future.wait([
        ref.read(performanceRepositoryProvider).getMyScore().catchError((_) => null),
        ref.read(performanceRepositoryProvider).getMyHistory().catchError((_) => <PerformanceTrend>[]),
      ]);

      if (mounted) {
        setState(() {
          _performance = results[0] as PerformanceData?;
          _history = results[1] as List<PerformanceTrend>;
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
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const SafeArea(
        child: Center(child: CircularProgressIndicator()),
      );
    }

    final performance = _performance;

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
              Text(
                'Performance',
                style: GoogleFonts.inter(
                  fontSize: AppSizes.s28,
                  fontWeight: FontWeight.bold,
                ),
              ).animate().fadeIn(duration: 600.ms),

              const SizedBox(height: 20),

              if (performance != null) ...[
                _ScoreOverview(performance: performance)
                    .animate().fadeIn(delay: 200.ms, duration: 600.ms),

                const SizedBox(height: 16),

                CustomCard(
                  padding: AppSizes.p16,
                  child: Column(
                    children: [
                      TabBar(
                        controller: _tabController,
                        labelColor: AppColors.primary,
                        unselectedLabelColor: AppColors.grey500,
                        indicatorColor: AppColors.primary,
                        labelStyle: GoogleFonts.inter(
                          fontSize: AppSizes.s14,
                          fontWeight: FontWeight.w600,
                        ),
                        tabs: const [
                          Tab(text: 'Weekly'),
                          Tab(text: 'Monthly'),
                          Tab(text: 'Yearly'),
                        ],
                      ),
                      const SizedBox(height: 16),
                      SizedBox(
                        height: 200,
                        child: TabBarView(
                          controller: _tabController,
                          children: [
                            _PerformanceChart(
                              data: _history.where((t) => t.date.isAfter(DateTime.now().subtract(const Duration(days: 7 * 12)))).toList(),
                            ),
                            _PerformanceChart(
                              data: _history,
                            ),
                            _PerformanceChart(
                              data: _history.where((t) => t.date.isAfter(DateTime.now().subtract(const Duration(days: 365)))).toList(),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ).animate().fadeIn(delay: 400.ms, duration: 600.ms),

                const SizedBox(height: 16),

                _CategoryBreakdown(scores: performance.categoryScores)
                    .animate().fadeIn(delay: 600.ms, duration: 600.ms),
              ] else
                CustomCard(
                  padding: AppSizes.p24,
                  child: Center(
                    child: Text(
                      'No performance data available',
                      style: GoogleFonts.inter(
                        fontSize: AppSizes.s14,
                        color: AppColors.grey400,
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ScoreOverview extends StatelessWidget {
  final PerformanceData performance;

  const _ScoreOverview({required this.performance});

  @override
  Widget build(BuildContext context) {
    return CustomCard(
      padding: AppSizes.p24,
      child: Row(
        children: [
          CircularPercentIndicator(
            radius: 60,
            lineWidth: 12,
            percent: (performance.overallScore / 100).clamp(0.0, 1.0),
            center: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  '${performance.overallScore.toInt()}',
                  style: GoogleFonts.inter(
                    fontSize: AppSizes.s28,
                    fontWeight: FontWeight.bold,
                    color: AppColors.primary,
                  ),
                ),
                Text(
                  'out of 100',
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
                  performance.period ?? 'Current Period',
                  style: GoogleFonts.inter(
                    fontSize: AppSizes.s18,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 4),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                  decoration: BoxDecoration(
                    color: AppColors.success.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(AppSizes.rFull),
                  ),
                  child: Text(
                    performance.gradeLabel,
                    style: GoogleFonts.inter(
                      fontSize: AppSizes.s13,
                      fontWeight: FontWeight.w600,
                      color: AppColors.success,
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  'Grade: ${performance.grade}',
                  style: GoogleFonts.inter(
                    fontSize: AppSizes.s14,
                    color: AppColors.grey500,
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

class _PerformanceChart extends StatelessWidget {
  final List<PerformanceTrend> data;

  const _PerformanceChart({required this.data});

  @override
  Widget build(BuildContext context) {
    if (data.isEmpty) {
      return Center(
        child: Text(
          'No trend data available',
          style: GoogleFonts.inter(
            fontSize: AppSizes.s14,
            color: AppColors.grey400,
          ),
        ),
      );
    }

    return LineChart(
      LineChartData(
        gridData: const FlGridData(show: false),
        titlesData: FlTitlesData(
          leftTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 30,
              interval: 1,
              getTitlesWidget: (value, meta) {
                final index = value.toInt();
                if (index >= 0 && index < data.length && index % 3 == 0) {
                  return Padding(
                    padding: const EdgeInsets.only(top: 8),
                    child: Text(
                      data[index].period,
                      style: GoogleFonts.inter(
                        fontSize: 10,
                        color: AppColors.grey400,
                      ),
                    ),
                  );
                }
                return const Text('');
              },
            ),
          ),
        ),
        borderData: FlBorderData(show: false),
        minX: 0,
        maxX: (data.length - 1).toDouble(),
        minY: 50,
        maxY: 100,
        lineBarsData: [
          LineChartBarData(
            spots: data.asMap().entries.map((entry) {
              return FlSpot(entry.key.toDouble(), entry.value.score);
            }).toList(),
            isCurved: true,
            color: AppColors.primary,
            barWidth: 3,
            isStrokeCapRound: true,
            dotData: const FlDotData(show: false),
            belowBarData: BarAreaData(
              show: true,
              color: AppColors.primary.withValues(alpha: 0.1),
            ),
          ),
        ],
      ),
    );
  }
}

class _CategoryBreakdown extends StatelessWidget {
  final Map<String, double> scores;

  const _CategoryBreakdown({required this.scores});

  @override
  Widget build(BuildContext context) {
    return CustomCard(
      padding: AppSizes.p20,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Score Breakdown',
            style: GoogleFonts.inter(
              fontSize: AppSizes.s18,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 16),
          ...scores.entries.map((entry) {
            return Padding(
              padding: const EdgeInsets.only(bottom: 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        entry.key,
                        style: GoogleFonts.inter(
                          fontSize: AppSizes.s14,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      Text(
                        '${entry.value.toInt()}%',
                        style: GoogleFonts.inter(
                          fontSize: AppSizes.s14,
                          fontWeight: FontWeight.w600,
                          color: AppColors.primary,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(4),
                    child: LinearProgressIndicator(
                      value: (entry.value / 100).clamp(0.0, 1.0),
                      backgroundColor: AppColors.grey200,
                      valueColor: const AlwaysStoppedAnimation<Color>(AppColors.primary),
                      minHeight: 8,
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
