import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'datasources/api_service.dart';
import 'datasources/local_storage.dart';
import 'repositories/auth_repository.dart';
import 'repositories/employee_repository.dart';
import 'repositories/leave_repository.dart';
import 'repositories/attendance_repository.dart';
import 'repositories/performance_repository.dart';
import 'repositories/notification_repository.dart';
import 'repositories/analytics_repository.dart';
import '../../services/biometric_service.dart';

final secureStorageProvider = Provider<FlutterSecureStorage>((ref) {
  return const FlutterSecureStorage();
});

final apiServiceProvider = Provider<ApiService>((ref) {
  return ApiService(storage: ref.watch(secureStorageProvider));
});

final localStorageProvider = Provider<LocalStorage>((ref) {
  throw UnimplementedError('Must be overridden in main()');
});

final biometricServiceProvider = Provider<BiometricService>((ref) {
  return BiometricService();
});

final authRepositoryProvider = Provider<AuthRepository>((ref) {
  return AuthRepository(
    api: ref.watch(apiServiceProvider),
    storage: ref.watch(localStorageProvider),
  );
});

final employeeRepositoryProvider = Provider<EmployeeRepository>((ref) {
  return EmployeeRepository(api: ref.watch(apiServiceProvider));
});

final leaveRepositoryProvider = Provider<LeaveRepository>((ref) {
  return LeaveRepository(api: ref.watch(apiServiceProvider));
});

final attendanceRepositoryProvider = Provider<AttendanceRepository>((ref) {
  return AttendanceRepository(api: ref.watch(apiServiceProvider));
});

final performanceRepositoryProvider = Provider<PerformanceRepository>((ref) {
  return PerformanceRepository(api: ref.watch(apiServiceProvider));
});

final notificationRepositoryProvider = Provider<NotificationRepository>((ref) {
  return NotificationRepository(api: ref.watch(apiServiceProvider));
});

final analyticsRepositoryProvider = Provider<AnalyticsRepository>((ref) {
  return AnalyticsRepository(api: ref.watch(apiServiceProvider));
});

final authStateProvider = StateNotifierProvider<AuthStateNotifier, AuthState>((ref) {
  return AuthStateNotifier(ref.watch(authRepositoryProvider));
});

class AuthState {
  final bool isLoading;
  final bool isAuthenticated;
  final String? error;

  const AuthState({
    this.isLoading = false,
    this.isAuthenticated = false,
    this.error,
  });

  AuthState copyWith({bool? isLoading, bool? isAuthenticated, String? error, bool clearError = false}) {
    return AuthState(
      isLoading: isLoading ?? this.isLoading,
      isAuthenticated: isAuthenticated ?? this.isAuthenticated,
      error: clearError ? null : (error ?? this.error),
    );
  }
}

class AuthStateNotifier extends StateNotifier<AuthState> {
  final AuthRepository _authRepository;

  AuthStateNotifier(this._authRepository) : super(const AuthState());

  Future<bool> login(String email, String password) async {
    state = state.copyWith(isLoading: true, clearError: true);
    try {
      await _authRepository.login(email, password);
      state = state.copyWith(isLoading: false, isAuthenticated: true);
      return true;
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
      return false;
    }
  }

  Future<bool> googleLogin(String idToken) async {
    state = state.copyWith(isLoading: true, clearError: true);
    try {
      await _authRepository.googleLogin(idToken);
      state = state.copyWith(isLoading: false, isAuthenticated: true);
      return true;
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
      return false;
    }
  }

  Future<void> logout() async {
    await _authRepository.logout();
    state = state.copyWith(isAuthenticated: false, clearError: true);
  }

  Future<bool> checkAuthStatus() async {
    state = state.copyWith(isLoading: true);
    try {
      final isAuth = await _authRepository.checkAuthStatus();
      state = state.copyWith(isLoading: false, isAuthenticated: isAuth);
      return isAuth;
    } catch (e) {
      state = state.copyWith(isLoading: false, isAuthenticated: false);
      return false;
    }
  }

  void clearError() {
    state = state.copyWith(clearError: true);
  }
}
