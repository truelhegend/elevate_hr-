enum LeaveType { annual, sick, emergency, personal, maternity, unpaid }
enum LeaveStatus { pending, approved, rejected, cancelled }

LeaveStatus _parseLeaveStatus(dynamic value) {
  if (value == null) return LeaveStatus.pending;
  switch (value.toString().toUpperCase()) {
    case 'APPROVED':
      return LeaveStatus.approved;
    case 'REJECTED':
      return LeaveStatus.rejected;
    case 'CANCELLED':
      return LeaveStatus.cancelled;
    default:
      return LeaveStatus.pending;
  }
}

class LeaveRequest {
  final String id;
  final String userId;
  final String userName;
  final String userAvatar;
  final LeaveType type;
  final DateTime startDate;
  final DateTime endDate;
  final String reason;
  final String? documentUrl;
  final LeaveStatus status;
  final DateTime createdAt;
  final String? reviewerComment;
  final DateTime? reviewedAt;
  final int totalDays;
  final List<LeaveApproval> approvals;

  const LeaveRequest({
    required this.id,
    required this.userId,
    required this.userName,
    this.userAvatar = '',
    required this.type,
    required this.startDate,
    required this.endDate,
    required this.reason,
    this.documentUrl,
    this.status = LeaveStatus.pending,
    required this.createdAt,
    this.reviewerComment,
    this.reviewedAt,
    this.totalDays = 0,
    this.approvals = const [],
  });

  int get computedTotalDays => totalDays > 0 ? totalDays : endDate.difference(startDate).inDays + 1;

  String get typeName {
    switch (type) {
      case LeaveType.annual:
        return 'Annual Leave';
      case LeaveType.sick:
        return 'Sick Leave';
      case LeaveType.emergency:
        return 'Emergency Leave';
      case LeaveType.personal:
        return 'Personal Leave';
      case LeaveType.maternity:
        return 'Maternity Leave';
      case LeaveType.unpaid:
        return 'Unpaid Leave';
    }
  }

  String get statusName {
    switch (status) {
      case LeaveStatus.pending:
        return 'Pending';
      case LeaveStatus.approved:
        return 'Approved';
      case LeaveStatus.rejected:
        return 'Rejected';
      case LeaveStatus.cancelled:
        return 'Cancelled';
    }
  }

  factory LeaveRequest.fromJson(Map<String, dynamic> json) {
    final employee = json['employee'] as Map<String, dynamic>?;
    final firstName = employee?['firstName'] ?? '';
    final lastName = employee?['lastName'] ?? '';
    final fullName = '$firstName $lastName'.trim();

    final approvalsList = (json['approvals'] as List<dynamic>?)
            ?.map((a) => LeaveApproval.fromJson(a as Map<String, dynamic>))
            .toList() ??
        [];

    String? reviewerComment;
    DateTime? reviewedAt;
    if (approvalsList.isNotEmpty) {
      final lastApproval = approvalsList.last;
      reviewerComment = lastApproval.comment;
      reviewedAt = lastApproval.createdAt;
    }

    return LeaveRequest(
      id: json['id'] ?? '',
      userId: json['employeeId'] ?? '',
      userName: fullName.isNotEmpty ? fullName : json['employeeId'] ?? '',
      type: _parseLeaveType(json['leaveType']),
      startDate: DateTime.tryParse(json['startDate'] ?? '') ?? DateTime.now(),
      endDate: DateTime.tryParse(json['endDate'] ?? '') ?? DateTime.now(),
      reason: json['reason'] ?? '',
      documentUrl: json['documentUrl'],
      status: _parseLeaveStatus(json['status']),
      createdAt: DateTime.tryParse(json['createdAt'] ?? '') ?? DateTime.now(),
      reviewerComment: reviewerComment,
      reviewedAt: reviewedAt,
      totalDays: json['totalDays'] ?? 0,
      approvals: approvalsList,
    );
  }

  static LeaveType _parseLeaveType(dynamic value) {
    if (value == null) return LeaveType.annual;
    switch (value.toString().toUpperCase()) {
      case 'SICK':
        return LeaveType.sick;
      case 'EMERGENCY':
        return LeaveType.emergency;
      case 'PERSONAL':
        return LeaveType.personal;
      case 'MATERNITY':
        return LeaveType.maternity;
      case 'UNPAID':
        return LeaveType.unpaid;
      default:
        return LeaveType.annual;
    }
  }

  Map<String, dynamic> toJson() {
    return {
      'leaveType': type.name.toUpperCase(),
      'startDate': startDate.toIso8601String(),
      'endDate': endDate.toIso8601String(),
      'reason': reason,
      'documentUrl': documentUrl,
    };
  }

  LeaveRequest copyWith({
    String? id,
    String? userId,
    String? userName,
    String? userAvatar,
    LeaveType? type,
    DateTime? startDate,
    DateTime? endDate,
    String? reason,
    String? documentUrl,
    LeaveStatus? status,
    DateTime? createdAt,
    String? reviewerComment,
    DateTime? reviewedAt,
    int? totalDays,
    List<LeaveApproval>? approvals,
  }) {
    return LeaveRequest(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      userName: userName ?? this.userName,
      userAvatar: userAvatar ?? this.userAvatar,
      type: type ?? this.type,
      startDate: startDate ?? this.startDate,
      endDate: endDate ?? this.endDate,
      reason: reason ?? this.reason,
      documentUrl: documentUrl ?? this.documentUrl,
      status: status ?? this.status,
      createdAt: createdAt ?? this.createdAt,
      reviewerComment: reviewerComment ?? this.reviewerComment,
      reviewedAt: reviewedAt ?? this.reviewedAt,
      totalDays: totalDays ?? this.totalDays,
      approvals: approvals ?? this.approvals,
    );
  }

  static List<LeaveRequest> get demoRequests => [
        LeaveRequest(
          id: 'L001',
          userId: '4',
          userName: 'Alex Thompson',
          type: LeaveType.annual,
          startDate: DateTime.now().add(const Duration(days: 2)),
          endDate: DateTime.now().add(const Duration(days: 5)),
          reason: 'Family vacation to Europe',
          status: LeaveStatus.pending,
          createdAt: DateTime.now().subtract(const Duration(days: 1)),
        ),
        LeaveRequest(
          id: 'L002',
          userId: '5',
          userName: 'Jessica Williams',
          type: LeaveType.sick,
          startDate: DateTime.now().subtract(const Duration(days: 2)),
          endDate: DateTime.now().subtract(const Duration(days: 1)),
          reason: 'Feeling unwell, need rest',
          status: LeaveStatus.approved,
          createdAt: DateTime.now().subtract(const Duration(days: 3)),
          reviewerComment: 'Get well soon!',
          reviewedAt: DateTime.now().subtract(const Duration(days: 2)),
        ),
        LeaveRequest(
          id: 'L003',
          userId: '6',
          userName: 'David Kim',
          type: LeaveType.emergency,
          startDate: DateTime.now(),
          endDate: DateTime.now().add(const Duration(days: 1)),
          reason: 'Family emergency',
          status: LeaveStatus.pending,
          createdAt: DateTime.now().subtract(const Duration(hours: 5)),
        ),
        LeaveRequest(
          id: 'L004',
          userId: '7',
          userName: 'Rachel Green',
          type: LeaveType.personal,
          startDate: DateTime.now().add(const Duration(days: 10)),
          endDate: DateTime.now().add(const Duration(days: 12)),
          reason: 'Moving to new apartment',
          status: LeaveStatus.rejected,
          createdAt: DateTime.now().subtract(const Duration(days: 5)),
          reviewerComment: 'Please reschedule during non-peak period',
          reviewedAt: DateTime.now().subtract(const Duration(days: 3)),
        ),
        LeaveRequest(
          id: 'L005',
          userId: '8',
          userName: 'James Wilson',
          type: LeaveType.annual,
          startDate: DateTime.now().add(const Duration(days: 7)),
          endDate: DateTime.now().add(const Duration(days: 10)),
          reason: 'Wedding anniversary trip',
          status: LeaveStatus.pending,
          createdAt: DateTime.now().subtract(const Duration(hours: 12)),
        ),
      ];
}

class LeaveApproval {
  final String id;
  final String approverId;
  final String approverName;
  final LeaveStatus status;
  final String? comment;
  final DateTime createdAt;

  const LeaveApproval({
    required this.id,
    required this.approverId,
    required this.approverName,
    required this.status,
    this.comment,
    required this.createdAt,
  });

  factory LeaveApproval.fromJson(Map<String, dynamic> json) {
    final approver = json['approver'] as Map<String, dynamic>?;
    final firstName = approver?['firstName'] ?? '';
    final lastName = approver?['lastName'] ?? '';
    final fullName = '$firstName $lastName'.trim();

    return LeaveApproval(
      id: json['id'] ?? '',
      approverId: json['approverId'] ?? '',
      approverName: fullName,
      status: _parseLeaveStatus(json['status']),
      comment: json['comment'],
      createdAt: DateTime.tryParse(json['createdAt'] ?? '') ?? DateTime.now(),
    );
  }
}

class LeaveBalance {
  final String type;
  final int totalDays;
  final int usedDays;
  final int remainingDays;

  const LeaveBalance({
    required this.type,
    required this.totalDays,
    required this.usedDays,
    required this.remainingDays,
  });

  factory LeaveBalance.fromJson(Map<String, dynamic> json) {
    return LeaveBalance(
      type: json['type'] ?? '',
      totalDays: json['totalDays'] ?? 0,
      usedDays: json['usedDays'] ?? 0,
      remainingDays: json['remainingDays'] ?? 0,
    );
  }

  String get typeName {
    switch (type.toUpperCase()) {
      case 'ANNUAL':
        return 'Annual Leave';
      case 'SICK':
        return 'Sick Leave';
      case 'EMERGENCY':
        return 'Emergency Leave';
      case 'PERSONAL':
        return 'Personal Leave';
      case 'MATERNITY':
        return 'Maternity Leave';
      case 'UNPAID':
        return 'Unpaid Leave';
      default:
        return type;
    }
  }
}
