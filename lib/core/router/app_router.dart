import 'package:go_router/go_router.dart';

import '../../features/splash/presentation/screens/splash_screen.dart';
import '../../features/authentication/presentation/screens/login_screen.dart';
import '../../features/authentication/application/auth_state_listenable.dart';
import '../../features/authentication/data/models/user_model.dart';
import '../../features/authentication/presentation/screens/profile_screen.dart';
import '../../features/dashboard/presentation/widgets/dashboard_layout.dart';
import '../../features/dashboard/presentation/screens/home_screen.dart';
import '../../features/employees/presentation/screens/employees_screen.dart';
import '../../features/employees/presentation/screens/create_employee_screen.dart';
import '../../features/employees/presentation/screens/edit_employee_screen.dart';
import '../../features/workplaces/presentation/screens/workplaces_screen.dart';
import '../../features/workplaces/presentation/screens/workplace_form_screen.dart';
import '../../features/attendance/presentation/screens/attendance_screen.dart';
import '../../features/history/presentation/screens/history_screen.dart';
import '../../features/medical_documents/presentation/screens/justificativos_screen.dart';
import '../../features/reports/presentation/screens/reports_screen.dart';
import 'app_routes.dart';

class AppRouter {
  static final _auth = AuthStateListenable();

  static final GoRouter router = GoRouter(
    initialLocation: '/',
    refreshListenable: _auth,

    redirect: (context, state) {
      final loggedIn = _auth.isLoggedIn;

      final goingToLogin = state.matchedLocation == '/login';
      final goingToSplash = state.matchedLocation == '/';

      if (!loggedIn) {
        return goingToLogin ? null : '/login';
      }

      if (loggedIn && (goingToLogin || goingToSplash)) {
        return '/dashboard';
      }

      final role = _auth.role;
      final path = state.matchedLocation;

      if (role != null) {
        if (role == UserRole.employee && path != '/' && !path.startsWith('/login') && !path.startsWith('/dashboard') && !path.startsWith('/profile')) {
          return '/dashboard';
        }
        if (role == UserRole.supervisor) {
          final restricted = ['/workplaces', '/history', '/justificativos', '/medical_documents', '/employees/create', '/employees/edit'];
          if (restricted.any((r) => path.startsWith(r))) {
            return '/dashboard';
          }
        }
      }

      return null;
    },

    routes: [
      GoRoute(
        path: '/',
        builder: (context, state) => const SplashScreen(),
      ),
      GoRoute(
        path: '/login',
        builder: (context, state) => const LoginScreen(),
      ),
      ShellRoute(
        builder: (context, state, child) => DashboardLayout(child: child),
        routes: [
          GoRoute(
            path: RoutePaths.dashboard,
            builder: (context, state) => const HomeScreen(),
          ),
          GoRoute(
            path: RoutePaths.employees,
            builder: (context, state) => const EmployeesScreen(),
          ),
          GoRoute(
            path: RoutePaths.workplaces,
            builder: (context, state) => const WorkplacesScreen(),
          ),
          GoRoute(
            path: RoutePaths.attendance,
            builder: (context, state) => const AttendanceScreen(),
          ),
          GoRoute(
            path: RoutePaths.history,
            builder: (context, state) => const HistoryScreen(),
          ),
          GoRoute(
            path: RoutePaths.justificativos,
            builder: (context, state) => const JustificativosScreen(),
          ),
          GoRoute(
            path: RoutePaths.reports,
            builder: (context, state) => const ReportsScreen(),
          ),
          GoRoute(
            path: RoutePaths.profile,
            builder: (context, state) => const ProfileScreen(),
          ),
          GoRoute(
            path: '/employees/create',
            builder: (context, state) => const CreateEmployeeScreen(),
          ),
          GoRoute(
            path: RoutePaths.editEmployee,
            builder: (context, state) => const EditEmployeeScreen(),
          ),
          GoRoute(
            path: RoutePaths.createWorkplace,
            builder: (context, state) => const WorkplaceFormScreen(),
          ),
          GoRoute(
            path: RoutePaths.editWorkplace,
            builder: (context, state) => const WorkplaceFormScreen(),
          ),
        ],
      ),
    ],
  );
}