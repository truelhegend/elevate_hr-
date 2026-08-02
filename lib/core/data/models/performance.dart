class PerformanceData {
  final String userId;
  final String userName;
  final double overallScore;
  final Map<String, double> categoryScores;
  final List<PerformanceTrend> trends;
  final String? review;
  final DateTime? lastReviewDate;
  final String? period;

  const PerformanceData({
    required this.userId,
    required this.userName,
    required this.overallScore,
    this.categoryScores = const {},
    this.trends = const [],
    this.review,
    this.lastReviewDate,
    this.period,
  });

  String get grade {
    if (overallScore >= 90) return 'A';
    if (overallScore >= 80) return 'B';
    if (overallScore >= 70) return 'C';
    if (overallScore >= 60) return 'D';
    return 'F';
  }

  String get gradeLabel {
    if (overallScore >= 90) return 'Excellent';
    if (overallScore >= 80) return 'Good';
    if (overallScore >= 70) return 'Average';
    if (overallScore >= 60) return 'Below Average';
    return 'Needs Improvement';
  }

  factory PerformanceData.fromJson(Map<String, dynamic> json) {
    return PerformanceData(
      userId: json['employeeId'] ?? '',
      userName: '',
      overallScore: (json['overallScore'] ?? 0).toDouble(),
      categoryScores: {
        'Attendance': (json['attendanceScore'] ?? 0).toDouble(),
        'Punctuality': (json['punctualityScore'] ?? 0).toDouble(),
        'Productivity': (json['productivityScore'] ?? 0).toDouble(),
        'Compliance': (json['complianceScore'] ?? 0).toDouble(),
      },
      lastReviewDate: json['calculatedAt'] != null
          ? DateTime.tryParse(json['calculatedAt'])
          : null,
      period: json['month'] != null && json['year'] != null
          ? '${json['year']}-${(json['month'] as int).toString().padLeft(2, '0')}'
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'employeeId': userId,
      'overallScore': overallScore,
      'attendanceScore': categoryScores['Attendance'],
      'punctualityScore': categoryScores['Punctuality'],
      'productivityScore': categoryScores['Productivity'],
      'complianceScore': categoryScores['Compliance'],
    };
  }

  static PerformanceData get demo => const PerformanceData(
        userId: '1',
        userName: 'Sarah Johnson',
        overallScore: 87,
        categoryScores: {
          'Attendance': 92,
          'Punctuality': 85,
          'Productivity': 88,
          'Compliance': 90,
        },
        review: 'Consistently exceeds expectations. Strong team player with excellent technical skills.',
        lastReviewDate: null,
      );

  static List<PerformanceData> get demoTeam => [
        const PerformanceData(
            userId: '1', userName: 'Sarah Johnson', overallScore: 87),
        const PerformanceData(
            userId: '4', userName: 'Alex Thompson', overallScore: 78),
        const PerformanceData(
            userId: '5', userName: 'Jessica Williams', overallScore: 92),
        const PerformanceData(
            userId: '6', userName: 'David Kim', overallScore: 74),
        const PerformanceData(
            userId: '7', userName: 'Rachel Green', overallScore: 81),
        const PerformanceData(
            userId: '8', userName: 'James Wilson', overallScore: 85),
      ];
}

class PerformanceTrend {
  final String period;
  final double score;
  final DateTime date;

  const PerformanceTrend({
    required this.period,
    required this.score,
    required this.date,
  });

  factory PerformanceTrend.fromJson(Map<String, dynamic> json) {
    final m = (json['month'] as int?) ?? 1;
    final y = (json['year'] as int?) ?? 2026;
    final monthNames = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
    ];
    final clampedMonth = m.clamp(1, 12);
    return PerformanceTrend(
      period: monthNames[clampedMonth - 1],
      score: (json['overallScore'] ?? 0).toDouble(),
      date: DateTime(y, clampedMonth),
    );
  }

  static List<PerformanceTrend> get demoWeekly => List.generate(
        12,
        (i) => PerformanceTrend(
          period: 'W${i + 1}',
          score: 70 + (i * 2.5) + (i % 3 == 0 ? 5 : 0),
          date: DateTime.now().subtract(Duration(days: (11 - i) * 7)),
        ),
      );

  static List<PerformanceTrend> get demoMonthly => List.generate(
        12,
        (i) => PerformanceTrend(
          period: [
            'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
            'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
          ][i],
          score: 65 + (i * 2.2) + (i % 2 == 0 ? 4 : 0),
          date: DateTime(2026, i + 1),
        ),
      );
}

class DepartmentPerformance {
  final String department;
  final double averageScore;
  final int employeeCount;
  final double improvement;

  const DepartmentPerformance({
    required this.department,
    required this.averageScore,
    required this.employeeCount,
    this.improvement = 0,
  });

  static List<DepartmentPerformance> get demo => [
        const DepartmentPerformance(
            department: 'Engineering', averageScore: 87, employeeCount: 24, improvement: 5.2),
        const DepartmentPerformance(
            department: 'Marketing', averageScore: 82, employeeCount: 16, improvement: 3.1),
        const DepartmentPerformance(
            department: 'Sales', averageScore: 79, employeeCount: 20, improvement: -1.5),
        const DepartmentPerformance(
            department: 'HR', averageScore: 85, employeeCount: 8, improvement: 2.8),
        const DepartmentPerformance(
            department: 'Finance', averageScore: 83, employeeCount: 12, improvement: 4.0),
      ];
}
