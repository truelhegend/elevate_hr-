enum AttendanceStatus { present, absent, late, onLeave, remote }

class AttendanceRecord {
  final String id;
  final String userId;
  final String? userName;
  final DateTime date;
  final DateTime? clockIn;
  final DateTime? clockOut;
  final AttendanceStatus status;
  final String? location;
  final double? workHours;
  final String? notes;

  const AttendanceRecord({
    required this.id,
    required this.userId,
    this.userName,
    required this.date,
    this.clockIn,
    this.clockOut,
    required this.status,
    this.location,
    this.workHours,
    this.notes,
  });

  String get statusName {
    switch (status) {
      case AttendanceStatus.present:
        return 'Present';
      case AttendanceStatus.absent:
        return 'Absent';
      case AttendanceStatus.late:
        return 'Late';
      case AttendanceStatus.onLeave:
        return 'On Leave';
      case AttendanceStatus.remote:
        return 'Remote';
    }
  }

  String get clockInTime =>
      clockIn != null ? '${clockIn!.hour}:${clockIn!.minute.toString().padLeft(2, '0')}' : '--:--';
  String get clockOutTime =>
      clockOut != null ? '${clockOut!.hour}:${clockOut!.minute.toString().padLeft(2, '0')}' : '--:--';

  factory AttendanceRecord.fromJson(Map<String, dynamic> json) {
    return AttendanceRecord(
      id: json['id'] ?? '',
      userId: json['employeeId'] ?? '',
      userName: json['userName'],
      date: DateTime.tryParse(json['date'] ?? '') ?? DateTime.now(),
      clockIn: json['clockIn'] != null ? DateTime.tryParse(json['clockIn']) : null,
      clockOut: json['clockOut'] != null ? DateTime.tryParse(json['clockOut']) : null,
      status: _parseStatus(json['status']),
      location: json['location'],
      workHours: json['workHours']?.toDouble(),
      notes: json['notes'],
    );
  }

  static AttendanceStatus _parseStatus(dynamic value) {
    if (value == null) return AttendanceStatus.absent;
    switch (value.toString().toUpperCase()) {
      case 'LATE':
        return AttendanceStatus.late;
      case 'ON_LEAVE':
        return AttendanceStatus.onLeave;
      case 'REMOTE':
        return AttendanceStatus.remote;
      case 'ABSENT':
        return AttendanceStatus.absent;
      default:
        return AttendanceStatus.present;
    }
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'employeeId': userId,
      'date': date.toIso8601String(),
      'clockIn': clockIn?.toIso8601String(),
      'clockOut': clockOut?.toIso8601String(),
      'status': status.name.toUpperCase(),
      'location': location,
      'workHours': workHours,
      'notes': notes,
    };
  }

  static List<AttendanceRecord> get demoRecords => [
        AttendanceRecord(
          id: 'A001',
          userId: '1',
          userName: 'Sarah Johnson',
          date: DateTime.now(),
          clockIn: DateTime.now().subtract(const Duration(hours: 8)),
          status: AttendanceStatus.present,
          workHours: 8,
        ),
        AttendanceRecord(
          id: 'A002',
          userId: '4',
          userName: 'Alex Thompson',
          date: DateTime.now(),
          clockIn: DateTime.now().subtract(const Duration(hours: 7)),
          status: AttendanceStatus.late,
          workHours: 7,
        ),
        AttendanceRecord(
          id: 'A003',
          userId: '5',
          userName: 'Jessica Williams',
          date: DateTime.now(),
          status: AttendanceStatus.onLeave,
        ),
        AttendanceRecord(
          id: 'A004',
          userId: '6',
          userName: 'David Kim',
          date: DateTime.now(),
          clockIn: DateTime.now().subtract(const Duration(hours: 6)),
          status: AttendanceStatus.remote,
          location: 'Home Office',
          workHours: 6,
        ),
        AttendanceRecord(
          id: 'A005',
          userId: '7',
          userName: 'Rachel Green',
          date: DateTime.now(),
          status: AttendanceStatus.absent,
        ),
        AttendanceRecord(
          id: 'A006',
          userId: '8',
          userName: 'James Wilson',
          date: DateTime.now(),
          clockIn: DateTime.now().subtract(const Duration(hours: 9)),
          status: AttendanceStatus.present,
          workHours: 9,
        ),
      ];
}
