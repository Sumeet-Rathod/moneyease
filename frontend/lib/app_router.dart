import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'core/widgets/app_nav_shell.dart';
import 'features/auth/auth_provider.dart';
import 'features/auth/splash_screen.dart';
import 'features/auth/intro_carousel_screen.dart';
import 'features/auth/login_screen.dart';
import 'features/auth/otp_screen.dart';
import 'features/onboarding/onboarding_wizard_screen.dart';
import 'features/goals/goal_planner_screen.dart';
import 'features/goals/future_visualizer_screen.dart';
import 'features/doubts/doubt_chat_screen.dart';
import 'features/risk_profile/risk_profiler_screen.dart';
import 'features/profile/profile_screen.dart';
import 'features/notifications/notifications_screen.dart';
import 'features/executive/executive_dashboard_screen.dart';
import 'features/executive/lead_detail_screen.dart';
import 'features/executive/admin_management_screen.dart';

final appRouterProvider = Provider<GoRouter>((ref) {
  return GoRouter(
    initialLocation: '/splash',
    refreshListenable: GoRouterRefreshStream(ref.watch(authProvider.notifier).stream),
    redirect: (BuildContext context, GoRouterState state) {
      final authState = ref.read(authProvider);
      final bool isAuthenticated = authState.isAuthenticated;
      final String loc = state.matchedLocation;

      final bool isAuthRoute = loc == '/login' || loc == '/otp' || loc == '/intro' || loc == '/splash';

      if (!isAuthenticated) {
        // Allow unauthenticated visitors to view splash, intro, login, otp
        if (isAuthRoute) return null;
        return '/login';
      }

      // Authenticated user
      final role = authState.user?.role ?? 'customer';

      if (isAuthRoute) {
        if (role == 'admin' || role == 'executive') {
          return '/exec';
        }
        return '/goals';
      }

      // Role authorization guards
      if (loc.startsWith('/exec') && role == 'customer') {
        return '/goals';
      }
      if (loc.startsWith('/admin') && role != 'admin') {
        return role == 'executive' ? '/exec' : '/goals';
      }

      return null;
    },
    routes: [
      GoRoute(
        path: '/splash',
        builder: (context, state) => const SplashScreen(),
      ),
      GoRoute(
        path: '/intro',
        builder: (context, state) => const IntroCarouselScreen(),
      ),
      GoRoute(
        path: '/login',
        builder: (context, state) => const LoginScreen(),
      ),
      GoRoute(
        path: '/otp',
        builder: (context, state) {
          final mobile = state.uri.queryParameters['mobile'] ?? '';
          return OtpScreen(mobile: mobile);
        },
      ),
      GoRoute(
        path: '/onboarding',
        builder: (context, state) => const OnboardingWizardScreen(),
      ),
      ShellRoute(
        builder: (context, state, child) => AppNavShell(child: child),
        routes: [
          GoRoute(
            path: '/goals',
            builder: (context, state) => const GoalPlannerScreen(),
            routes: [
              GoRoute(
                path: 'visualizer',
                builder: (context, state) => const FutureVisualizerScreen(),
              ),
            ],
          ),
          GoRoute(
            path: '/doubts',
            builder: (context, state) => const DoubtChatScreen(),
          ),
          GoRoute(
            path: '/risk',
            builder: (context, state) => const RiskProfilerScreen(),
          ),
          GoRoute(
            path: '/profile',
            builder: (context, state) => const ProfileScreen(),
          ),
          GoRoute(
            path: '/notifications',
            builder: (context, state) => const NotificationsScreen(),
          ),
          GoRoute(
            path: '/exec',
            builder: (context, state) => const ExecutiveDashboardScreen(),
            routes: [
              GoRoute(
                path: 'leads/:id',
                builder: (context, state) {
                  final leadId = int.tryParse(state.pathParameters['id'] ?? '0') ?? 0;
                  return LeadDetailScreen(leadId: leadId);
                },
              ),
            ],
          ),
          GoRoute(
            path: '/admin',
            builder: (context, state) => const AdminManagementScreen(),
          ),
        ],
      ),
    ],
  );
});

class GoRouterRefreshStream extends ChangeNotifier {
  GoRouterRefreshStream(Stream<dynamic> stream) {
    notifyListeners();
    _subscription = stream.asBroadcastStream().listen((_) => notifyListeners());
  }

  late final dynamic _subscription;

  @override
  void dispose() {
    _subscription.cancel();
    super.dispose();
  }
}
