import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:miningguard/features/auth/providers/auth_providers.dart';
import 'package:miningguard/features/auth/screens/language_selection_screen.dart';
import 'package:miningguard/features/auth/screens/login_screen.dart';
import 'package:miningguard/features/auth/screens/profile_screen.dart';
import 'package:miningguard/features/auth/screens/signup_screen.dart';
import 'package:miningguard/features/checklist/screens/checklist_history_screen.dart';
import 'package:miningguard/features/checklist/screens/checklist_screen.dart';
import 'package:miningguard/features/checklist/screens/checklist_success_screen.dart';
import 'package:miningguard/features/education/domain/safety_video.dart';
import 'package:miningguard/features/education/presentation/screens/category_browse_screen.dart';
import 'package:miningguard/features/education/presentation/screens/education_screen.dart';
import 'package:miningguard/features/education/presentation/screens/video_player_screen.dart';
import 'package:miningguard/features/hazard_report/models/hazard_report_model.dart';
import 'package:miningguard/features/hazard_report/screens/my_reports_screen.dart';
import 'package:miningguard/features/hazard_report/screens/report_detail_screen.dart';
import 'package:miningguard/features/hazard_report/screens/report_input_screen.dart';
import 'package:miningguard/shared/models/user_model.dart';

// ── Route constants ───────────────────────────────────────────────────────────

class AppRoutes {
  AppRoutes._();

  static const String splash = '/';
  static const String login = '/login';
  static const String signup = '/signup';
  static const String languageSelect = '/language-select';

  // Worker routes
  static const String workerHome = '/worker/home';
  static const String checklist = '/worker/checklist';
  static const String checklistHistory = '/worker/checklist/history';
  static const String checklistSuccess = '/worker/checklist/success';
  static const String reportHazard = '/worker/report';
  static const String myReports = '/worker/reports';
  static const String reportDetail = '/worker/reports/detail';
  static const String education = '/worker/education';
  static const String workerProfile = '/worker/profile';

  // Supervisor routes
  static const String supervisorDashboard = '/supervisor/dashboard';
  static const String workersList = '/supervisor/workers';
  static const String workerDetail = '/supervisor/workers/:uid';
  static const String pendingReports = '/supervisor/reports';
  static const String supervisorReportDetail = '/supervisor/reports/detail';

  // Admin routes
  static const String adminPanel = '/admin/panel';
  static const String userManagement = '/admin/users';
  static const String contentManagement = '/admin/content';
  static const String analytics = '/admin/analytics';
}

// ── Placeholder screens (replaced in later phases) ───────────────────────────

class _SplashScreen extends StatelessWidget {
  const _SplashScreen();

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      backgroundColor: Color(0xFF1A1A2E),
      body: Center(
        child: CircularProgressIndicator(color: Color(0xFFF5A623)),
      ),
    );
  }
}

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Worker Dashboard')),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.home, size: 64, color: Colors.amber),
            const SizedBox(height: 16),
            const Text('Worker Dashboard'),
            const SizedBox(height: 24),
            FilledButton.icon(
              onPressed: () => context.go(AppRoutes.checklist),
              icon: const Icon(Icons.checklist),
              label: const Text("Today's Safety Checklist"),
            ),
            const SizedBox(height: 12),
            FilledButton.icon(
              onPressed: () => context.go(AppRoutes.reportHazard),
              icon: const Icon(Icons.warning_amber),
              label: const Text('Report Hazard'),
            ),
            const SizedBox(height: 12),
            OutlinedButton.icon(
              onPressed: () => context.go(AppRoutes.myReports),
              icon: const Icon(Icons.list_alt),
              label: const Text('My Hazard Reports'),
            ),
            const SizedBox(height: 12),
            OutlinedButton.icon(
              onPressed: () => context.go(AppRoutes.checklistHistory),
              icon: const Icon(Icons.history),
              label: const Text('Checklist History'),
            ),
            const SizedBox(height: 12),
            OutlinedButton.icon(
              onPressed: () => context.go(AppRoutes.education),
              icon: const Icon(Icons.play_circle_outline),
              label: const Text('Safety Education'),
            ),
            const SizedBox(height: 12),
            TextButton(
              onPressed: () => context.go(AppRoutes.workerProfile),
              child: const Text('My Profile'),
            ),
          ],
        ),
      ),
    );
  }
}

class SupervisorDashboardScreen extends StatelessWidget {
  const SupervisorDashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Supervisor Dashboard')),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.supervisor_account, size: 64, color: Colors.amber),
            const SizedBox(height: 16),
            const Text('Supervisor Dashboard'),
            const SizedBox(height: 24),
            FilledButton.icon(
              onPressed: () => context.go(AppRoutes.pendingReports),
              icon: const Icon(Icons.warning_amber),
              label: const Text('Mine Reports'),
            ),
            const SizedBox(height: 12),
            ElevatedButton(
              onPressed: () => context.go(AppRoutes.workerProfile),
              child: const Text('My Profile'),
            ),
          ],
        ),
      ),
    );
  }
}

class AdminPanelScreen extends StatelessWidget {
  const AdminPanelScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Admin Panel')),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.admin_panel_settings,
                size: 64, color: Colors.amber),
            const SizedBox(height: 16),
            const Text('Admin Panel — Phase 3 coming soon'),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: () => context.go(AppRoutes.workerProfile),
              child: const Text('My Profile'),
            ),
          ],
        ),
      ),
    );
  }
}

class PlaceholderScreen extends StatelessWidget {
  const PlaceholderScreen({super.key, required this.routeName});
  final String routeName;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(routeName)),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.construction, size: 64, color: Colors.amber),
            const SizedBox(height: 16),
            Text(
              'Screen not yet built:\n$routeName',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.titleMedium,
            ),
          ],
        ),
      ),
    );
  }
}

// ── Supervisor mine reports screen ────────────────────────────────────────────

class _SupervisorReportsScreen extends ConsumerWidget {
  const _SupervisorReportsScreen();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final userAsync = ref.watch(currentUserModelProvider);
    final user = userAsync.valueOrNull;
    if (user == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Mine Reports')),
        body: const Center(child: CircularProgressIndicator()),
      );
    }
    // Reuse MyReportsScreen layout but for supervisor: show all mine reports
    // Full implementation in a later phase; for now shows a placeholder with mine ID
    return Scaffold(
      appBar: AppBar(title: const Text('Mine Reports')),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.warning_amber, size: 64, color: Colors.amber),
            const SizedBox(height: 16),
            Text('Mine: ${user.mineId}'),
            const SizedBox(height: 8),
            const Text('Hazard reports for your mine appear here'),
          ],
        ),
      ),
    );
  }
}

// ── Router provider ───────────────────────────────────────────────────────────

final appRouterProvider = Provider<GoRouter>((ref) {
  final authNotifier = _AuthRouteNotifier(ref);

  final router = GoRouter(
    initialLocation: AppRoutes.splash,
    debugLogDiagnostics: true,
    refreshListenable: authNotifier,
    redirect: (context, state) {
      final authAsync = ref.read(authStateProvider);
      final userAsync = ref.read(currentUserModelProvider);

      // Step 1 — still resolving auth state: hold on splash
      if (authAsync.isLoading) return AppRoutes.splash;

      final isAuthenticated = authAsync.valueOrNull != null;
      final path = state.uri.path;

      // Step 2 — not signed in: send to login
      if (!isAuthenticated) {
        return path == AppRoutes.login ? null : AppRoutes.login;
      }

      // Step 3 — signed in but no Firestore doc yet: send to signup
      if (userAsync.isLoading) return AppRoutes.splash;
      final user = userAsync.valueOrNull;
      if (user == null) {
        if (path == AppRoutes.signup) return null;
        return AppRoutes.signup;
      }

      // Step 4 — already onboarded but still on auth screens: redirect home
      if (path == AppRoutes.login ||
          path == AppRoutes.signup ||
          path == AppRoutes.languageSelect) {
        return _roleHome(user.role);
      }

      // Step 5 — enforce role-based home
      if (path == AppRoutes.splash) return _roleHome(user.role);

      return null;
    },
    routes: [
      GoRoute(
        path: AppRoutes.splash,
        builder: (_, __) => const _SplashScreen(),
      ),
      GoRoute(
        path: AppRoutes.login,
        builder: (_, __) => const LoginScreen(),
      ),
      GoRoute(
        path: AppRoutes.signup,
        builder: (_, __) => const SignupScreen(),
      ),
      GoRoute(
        path: AppRoutes.languageSelect,
        builder: (_, __) => const LanguageSelectionScreen(),
      ),

      // Worker
      GoRoute(
        path: AppRoutes.workerHome,
        builder: (_, __) => const HomeScreen(),
      ),
      GoRoute(
        path: AppRoutes.workerProfile,
        builder: (_, __) => const ProfileScreen(),
      ),
      GoRoute(
        path: AppRoutes.checklist,
        builder: (_, __) => const ChecklistScreen(),
      ),
      GoRoute(
        path: AppRoutes.checklistHistory,
        builder: (_, __) => const ChecklistHistoryScreen(),
      ),
      GoRoute(
        path: AppRoutes.checklistSuccess,
        builder: (_, state) {
          final score = (state.extra as double?) ?? 0.0;
          return ChecklistSuccessScreen(complianceScore: score);
        },
      ),
      GoRoute(
        path: AppRoutes.reportHazard,
        builder: (_, __) => const ReportInputScreen(),
      ),
      GoRoute(
        path: AppRoutes.myReports,
        builder: (_, __) => const MyReportsScreen(),
      ),
      GoRoute(
        path: AppRoutes.reportDetail,
        builder: (_, state) {
          final report = state.extra as HazardReportModel;
          return ReportDetailScreen(report: report);
        },
      ),
      GoRoute(
        path: AppRoutes.education,
        builder: (_, __) => const EducationScreen(),
        routes: [
          GoRoute(
            path: 'player',
            builder: (context, state) => VideoPlayerScreen(
              video: state.extra as SafetyVideo,
            ),
          ),
          GoRoute(
            path: 'category/:categoryId',
            builder: (context, state) => CategoryBrowseScreen(
              category: state.pathParameters['categoryId']!,
            ),
          ),
        ],
      ),

      // Supervisor
      GoRoute(
        path: AppRoutes.supervisorDashboard,
        builder: (_, __) => const SupervisorDashboardScreen(),
      ),
      GoRoute(
        path: AppRoutes.workersList,
        builder: (_, __) => const PlaceholderScreen(routeName: 'Workers List'),
      ),
      GoRoute(
        path: AppRoutes.workerDetail,
        builder: (context, state) {
          final uid = state.pathParameters['uid'] ?? '';
          return PlaceholderScreen(routeName: 'Worker Detail: $uid');
        },
      ),
      GoRoute(
        path: AppRoutes.pendingReports,
        builder: (_, __) => const _SupervisorReportsScreen(),
      ),
      GoRoute(
        path: AppRoutes.supervisorReportDetail,
        builder: (_, state) {
          final report = state.extra as HazardReportModel;
          return ReportDetailScreen(report: report);
        },
      ),

      // Admin
      GoRoute(
        path: AppRoutes.adminPanel,
        builder: (_, __) => const AdminPanelScreen(),
      ),
      GoRoute(
        path: AppRoutes.userManagement,
        builder: (_, __) => const PlaceholderScreen(routeName: 'User Management'),
      ),
      GoRoute(
        path: AppRoutes.contentManagement,
        builder: (_, __) =>
            const PlaceholderScreen(routeName: 'Content Management'),
      ),
      GoRoute(
        path: AppRoutes.analytics,
        builder: (_, __) => const PlaceholderScreen(routeName: 'Analytics'),
      ),
    ],
    errorBuilder: (context, state) => Scaffold(
      body: Center(child: Text('Route not found: ${state.uri}')),
    ),
  );

  return router;
});

String _roleHome(UserRole role) {
  switch (role) {
    case UserRole.admin:
      return AppRoutes.adminPanel;
    case UserRole.supervisor:
      return AppRoutes.supervisorDashboard;
    case UserRole.worker:
      return AppRoutes.workerHome;
  }
}

/// Listens to auth and user state changes and notifies GoRouter to re-evaluate
/// its redirect function.
class _AuthRouteNotifier extends ChangeNotifier {
  _AuthRouteNotifier(Ref ref) {
    ref.listen(authStateProvider, (_, __) => notifyListeners());
    ref.listen(currentUserModelProvider, (_, __) => notifyListeners());
  }
}
