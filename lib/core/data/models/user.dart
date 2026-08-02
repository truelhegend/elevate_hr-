enum UserRole { employee, manager, ceo, admin }

class User {
  final String id;
  final String firstName;
  final String lastName;
  final String email;
  final String employeeId;
  final String? avatarUrl;
  final String department;
  final String position;
  final UserRole role;
  final double performanceScore;
  final Map<String, int> leaveBalance;
  final Map<String, dynamic>? attendance;
  final String? phone;

  const User({
    required this.id,
    required this.firstName,
    required this.lastName,
    required this.email,
    required this.employeeId,
    this.avatarUrl,
    required this.department,
    required this.position,
    required this.role,
    this.performanceScore = 0,
    this.leaveBalance = const {},
    this.attendance,
    this.phone,
  });

  String get name => '$firstName $lastName'.trim();

  String get initials {
    final fn = firstName.isNotEmpty ? firstName[0] : '';
    final ln = lastName.isNotEmpty ? lastName[0] : '';
    return '$fn$ln'.toUpperCase();
  }

  User copyWith({
    String? id,
    String? firstName,
    String? lastName,
    String? email,
    String? employeeId,
    String? avatarUrl,
    String? department,
    String? position,
    UserRole? role,
    double? performanceScore,
    Map<String, int>? leaveBalance,
    Map<String, dynamic>? attendance,
    String? phone,
  }) {
    return User(
      id: id ?? this.id,
      firstName: firstName ?? this.firstName,
      lastName: lastName ?? this.lastName,
      email: email ?? this.email,
      employeeId: employeeId ?? this.employeeId,
      avatarUrl: avatarUrl ?? this.avatarUrl,
      department: department ?? this.department,
      position: position ?? this.position,
      role: role ?? this.role,
      performanceScore: performanceScore ?? this.performanceScore,
      leaveBalance: leaveBalance ?? this.leaveBalance,
      attendance: attendance ?? this.attendance,
      phone: phone ?? this.phone,
    );
  }

  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      id: json['id'] ?? '',
      firstName: json['firstName'] ?? '',
      lastName: json['lastName'] ?? '',
      email: json['email'] ?? '',
      employeeId: json['employeeId'] ?? '',
      avatarUrl: json['avatarUrl'],
      department: json['department'] is String
          ? json['department']
          : json['department']?['name'] ?? '',
      position: json['position'] ?? '',
      role: _parseRole(json['role']),
      performanceScore: (json['performanceScore'] ?? 0).toDouble(),
      leaveBalance: Map<String, int>.from(json['leaveBalance'] ?? {}),
      attendance: json['attendance'],
      phone: json['phone'],
    );
  }

  static UserRole _parseRole(dynamic value) {
    if (value == null) return UserRole.employee;
    final str = value.toString().toUpperCase();
    switch (str) {
      case 'CEO':
        return UserRole.ceo;
      case 'MANAGER':
        return UserRole.manager;
      case 'ADMIN':
        return UserRole.admin;
      default:
        return UserRole.employee;
    }
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'firstName': firstName,
      'lastName': lastName,
      'email': email,
      'employeeId': employeeId,
      'avatarUrl': avatarUrl,
      'department': department,
      'position': position,
      'role': role.name.toUpperCase(),
      'performanceScore': performanceScore,
      'leaveBalance': leaveBalance,
      'attendance': attendance,
      'phone': phone,
    };
  }

  static User get demoEmployee => const User(
        id: '1',
        firstName: 'Sarah',
        lastName: 'Johnson',
        email: 'sarah.johnson@elevatehr.com',
        employeeId: 'EMP001',
        department: 'Engineering',
        position: 'Senior Developer',
        role: UserRole.employee,
        performanceScore: 87,
        leaveBalance: {
          'Annual': 12,
          'Sick': 5,
          'Emergency': 3,
        },
        attendance: {
          'present': 22,
          'absent': 1,
          'late': 2,
        },
      );

  static User get demoManager => const User(
        id: '2',
        firstName: 'Michael',
        lastName: 'Chen',
        email: 'michael.chen@elevatehr.com',
        employeeId: 'MGR001',
        department: 'Engineering',
        position: 'Engineering Manager',
        role: UserRole.manager,
        performanceScore: 92,
        leaveBalance: {
          'Annual': 15,
          'Sick': 8,
          'Emergency': 5,
        },
      );

  static User get demoCEO => const User(
        id: '3',
        firstName: 'Emily',
        lastName: 'Rodriguez',
        email: 'emily.rodriguez@elevatehr.com',
        employeeId: 'CEO001',
        department: 'Executive',
        position: 'Chief Executive Officer',
        role: UserRole.ceo,
        performanceScore: 95,
        leaveBalance: {
          'Annual': 20,
          'Sick': 10,
          'Emergency': 8,
        },
      );
}
