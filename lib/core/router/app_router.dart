import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../features/splash/splash_screen.dart';
import '../../features/onboarding/onboarding_screen.dart';
import '../../features/auth/presentation/login_screen.dart';
import '../../features/dashboard/presentation/dashboard_shell.dart';
import '../../features/dashboard/presentation/employee_dashboard.dart';
import '../../features/dashboard/presentation/manager_dashboard.dart';
import '../../features/dashboard/presentation/ceo_dashboard.dart';
import '../../features/performance/presentation/performance_screen.dart';
import '../../features/chat/presentation/chat_screen.dart';
import '../../features/profile/presentation/profile_screen.dart';
import '../../features/leave/presentation/leave_request_screen.dart';
import '../../features/notifications/presentation/notifications_screen.dart';
import '../../features/team/presentation/team_availability_screen.dart';
import '../data/providers.dart';
import '../data/models/user.dart';

final GlobalKey<NavigatorState> _rootNavigatorKey = GlobalKey<NavigatorState>();

final appRouterProvider = Provider<GoRouter>((ref) {
  final authState = ref.watch(authStateProvider);

  return GoRouter(
    navigatorKey: _rootNavigatorKey,
    initialLocation: '/splash',
    redirect: (context, state) {
      final isOnAuthRoute = state.matchedLocation == '/login' ||
          state.matchedLocation == '/onboarding' ||
          state.matchedLocation == '/splash';
      final isAuthenticated = authState.isAuthenticated;

      if (!isAuthenticated && !isOnAuthRoute) {
        return '/login';
      }
      if (isAuthenticated && isOnAuthRoute) {
        return '/dashboard';
      }
      return null;
    },
    routes: [
      GoRoute(
        path: '/splash',
        builder: (context, state) => const SplashScreen(),
      ),
      GoRoute(
        path: '/onboarding',
        builder: (context, state) => const OnboardingScreen(),
      ),
      GoRoute(
        path: '/login',
        builder: (context, state) => const LoginScreen(),
      ),
      StatefulShellRoute.indexedStack(
        builder: (context, state, navigationShell) => DashboardShell(
          navigationShell: navigationShell,
        ),
        branches: [
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/dashboard',
                builder: (context, state) => const _RoleDashboard(),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/performance',
                builder: (context, state) => const PerformanceScreen(),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/team',
                builder: (context, state) => const TeamAvailabilityScreen(),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/chat',
                builder: (context, state) => const ChatScreen(),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/profile',
                builder: (context, state) => const ProfileScreen(),
              ),
            ],
          ),
        ],
      ),
      GoRoute(
        path: '/leave-request',
        parentNavigatorKey: _rootNavigatorKey,
        builder: (context, state) => const LeaveRequestScreen(),
      ),
      GoRoute(
        path: '/notifications',
        parentNavigatorKey: _rootNavigatorKey,
        builder: (context, state) => const NotificationsScreen(),
      ),
      GoRoute(
        path: '/team-availability',
        parentNavigatorKey: _rootNavigatorKey,
        builder: (context, state) => const TeamAvailabilityScreen(),
      ),
    ],
  );
});

class _RoleDashboard extends ConsumerWidget {
  const _RoleDashboard();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authRepo = ref.watch(authRepositoryProvider);
    final user = authRepo.currentUser;

    if (user == null) return const EmployeeDashboard();

    switch (user.role) {
      case UserRole.ceo:
        return const CeoDashboard();
      case UserRole.manager:
        return const ManagerDashboard();
      case UserRole.employee:
      case UserRole.admin:
        return const EmployeeDashboard();
    }
  }
}
