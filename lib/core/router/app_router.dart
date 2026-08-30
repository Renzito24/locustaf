import 'package:go_router/go_router.dart';

import '../../features/splash/presentation/screens/splash_screen.dart';
import '../../features/authentication/presentation/screens/login_screen.dart';
import '../../features/authentication/application/auth_state_listenable.dart';
import '../../core/models/company_model.dart';
import '../../core/models/user_model.dart';
import '../../features/profile/presentation/screens/profile_screen.dart';
import '../../features/dashboard/presentation/widgets/dashboard_layout.dart';
import '../../features/dashboard/presentation/screens/home_screen.dart';
import '../../features/employees/presentation/screens/employees_screen.dart';
import '../../features/employees/presentation/screens/create_employee_screen.dart';
import '../../features/employees/presentation/screens/edit_employee_screen.dart';
import '../../features/workplaces/presentation/screens/workplaces_screen.dart';
import '../../features/workplaces/presentation/screens/workplace_form_screen.dart';
import '../../features/attendance/presentation/screens/attendance_screen.dart';
import '../../features/history/presentation/screens/history_screen.dart';
import '../../features/incidences/data/models/incidence_model.dart';
import '../../features/incidences/presentation/screens/create_incidence_screen.dart';
import '../../features/incidences/presentation/screens/edit_incidence_screen.dart';
import '../../features/incidences/presentation/screens/incidences_screen.dart';
import '../../features/medical_documents/data/models/medical_document_model.dart';
import '../../features/medical_documents/presentation/screens/create_medical_document_screen.dart';
import '../../features/medical_documents/presentation/screens/edit_medical_document_screen.dart';
import '../../features/medical_documents/presentation/screens/medical_documents_screen.dart';
import '../../features/reports/presentation/screens/reports_screen.dart';
import '../../features/reports/presentation/screens/employee_reports_screen.dart';
import '../../features/justificativos/presentation/screens/employee_justificativos_screen.dart';
import '../../features/justificativos/presentation/screens/employee_create_incidence_screen.dart';
import '../../features/justificativos/presentation/screens/employee_create_medical_document_screen.dart';
import '../../features/companies/presentation/screens/companies_screen.dart';
import '../../features/companies/presentation/screens/company_form_screen.dart';
import '../../features/companies/presentation/screens/company_settings_screen.dart';
import '../../features/companies/presentation/screens/onboarding_screen.dart';
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

      // Si el usuario está autenticado pero su cuenta está bloqueada
      // (desactivada o eliminada), forzar cierre de sesión.
      if (loggedIn && _auth.isUserBlocked) {
        return goingToLogin ? null : '/login?blocked=true';
      }

      // Si la empresa del usuario está inactiva, bloquear el acceso a la app.
      if (loggedIn && _auth.isCompanyInactive) {
        return goingToLogin ? null : '/login?company=inactive';
      }

      // Si el usuario está autenticado pero no tiene empresa, debe completar
      // el onboarding (crear su empresa).
      if (loggedIn && _auth.needsOnboarding) {
        final goingToOnboarding = state.matchedLocation == '/onboarding';
        return goingToOnboarding ? null : '/onboarding';
      }

      // Si el usuario está autenticado, ya no necesita onboarding (tiene
      // empresa o es superadmin) y está en /onboarding, salir de ahí.
      if (loggedIn && state.matchedLocation == '/onboarding') {
        return _auth.isEmployee ? '/attendance' : '/dashboard';
      }

      final role = _auth.role;

      if (loggedIn && (goingToLogin || goingToSplash)) {
        return role == UserRole.employee ? '/attendance' : '/dashboard';
      }

      final path = state.matchedLocation;

      if (role == UserRole.employee) {
        final allowed = ['/attendance', '/reports', '/profile', '/justificativos'];
        if (!allowed.any((r) => path.startsWith(r)) && path != '/' && !path.startsWith('/login')) {
          return '/attendance';
        }
      }

      if (role == UserRole.supervisor) {
        final restricted = ['/attendance', '/settings', '/medical_documents', '/reports', '/employees/create', '/employees/edit', '/workplaces/create', '/workplaces/edit', '/incidences/create', '/incidences/edit'];
        if (restricted.any((r) => path.startsWith(r))) {
          return '/dashboard';
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
      GoRoute(
        path: '/onboarding',
        builder: (context, state) => const OnboardingScreen(),
      ),
      ShellRoute(
        builder: (context, state, child) => DashboardLayout(child: child),
        routes: [
          GoRoute(
            path: RoutePaths.dashboard,
            builder: (context, state) => const HomeScreen(),
          ),
          GoRoute(
            path: RoutePaths.companies,
            builder: (context, state) => const CompaniesScreen(),
          ),
          GoRoute(
            path: RoutePaths.createCompany,
            builder: (context, state) => const CompanyFormScreen(),
          ),
          GoRoute(
            path: RoutePaths.editCompany,
            builder: (context, state) => CompanyFormScreen(
              company: state.extra as CompanyModel?,
            ),
          ),
          GoRoute(
            path: RoutePaths.companySettings,
            builder: (context, state) => const CompanySettingsScreen(),
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
            path: RoutePaths.medicalDocuments,
            builder: (context, state) => const MedicalDocumentsScreen(),
          ),
          GoRoute(
            path: RoutePaths.createMedicalDocument,
            builder: (context, state) => const CreateMedicalDocumentScreen(),
          ),
          GoRoute(
            path: RoutePaths.editMedicalDocument,
            builder: (context, state) {
              final doc = state.extra as MedicalDocumentModel;
              return EditMedicalDocumentScreen(document: doc);
            },
          ),
          GoRoute(
            path: RoutePaths.incidences,
            builder: (context, state) => const IncidencesScreen(),
          ),
          GoRoute(
            path: RoutePaths.createIncidence,
            builder: (context, state) => const CreateIncidenceScreen(),
          ),
          GoRoute(
            path: RoutePaths.editIncidence,
            builder: (context, state) {
              final inc = state.extra as IncidenceModel;
              return EditIncidenceScreen(incidence: inc);
            },
          ),
          GoRoute(
            path: RoutePaths.reports,
            builder: (context, state) {
              final role = _auth.role;
              if (role == UserRole.employee) {
                return const EmployeeReportsScreen();
              }
              return const ReportsScreen();
            },
          ),
          GoRoute(
            path: RoutePaths.profile,
            builder: (context, state) => const ProfileScreen(),
          ),
          GoRoute(
            path: RoutePaths.employeeJustificativos,
            builder: (context, state) => const EmployeeJustificativosScreen(),
          ),
          GoRoute(
            path: RoutePaths.employeeCreateIncidence,
            builder: (context, state) => const EmployeeCreateIncidenceScreen(),
          ),
          GoRoute(
            path: RoutePaths.employeeCreateMedicalDocument,
            builder: (context, state) => const EmployeeCreateMedicalDocumentScreen(),
          ),
          GoRoute(
            path: RoutePaths.createEmployee,
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