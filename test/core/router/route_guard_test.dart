import 'package:app_locustaf/core/models/user_model.dart';
import 'package:app_locustaf/core/router/route_guard.dart';
import 'package:flutter_test/flutter_test.dart';

/// Test E2E de control de acceso por ruta: cada escenario usa la MÍSMISMA
/// función [resolveRedirect] que el `redirect` del GoRouter real, por lo que
/// valida la autorización a nivel de navegación (defensa en profundidad,
/// nunca confiar solo en botones ocultos).
void main() {
  RouteGuardState guard({
    bool loggedIn = true,
    bool blocked = false,
    bool companyInactive = false,
    bool onboarding = false,
    UserRole? role = UserRole.employee,
  }) {
    return RouteGuardState(
      isLoggedIn: loggedIn,
      isUserBlocked: blocked,
      isCompanyInactive: companyInactive,
      needsOnboarding: onboarding,
      role: role,
      isEmployee: role == UserRole.employee,
    );
  }

  group('resolveRedirect — sesión', () {
    test('no logueado en /login: se queda (null)', () {
      expect(resolveRedirect(guard(loggedIn: false), '/login'), isNull);
    });

    test('no logueado en cualquier ruta: redirige a /login', () {
      expect(resolveRedirect(guard(loggedIn: false), '/dashboard'), '/login');
      expect(resolveRedirect(guard(loggedIn: false), '/attendance'), '/login');
      expect(resolveRedirect(guard(loggedIn: false), '/onboarding'), '/login');
    });

    test('usuario bloqueado no en /login: /login?blocked=true', () {
      expect(
        resolveRedirect(guard(blocked: true), '/dashboard'),
        '/login?blocked=true',
      );
    });

    test('usuario bloqueado ya en /login: se queda (null)', () {
      expect(resolveRedirect(guard(blocked: true), '/login'), isNull);
    });

    test('empresa inactiva no en /login: /login?company=inactive', () {
      expect(
        resolveRedirect(guard(companyInactive: true), '/attendance'),
        '/login?company=inactive',
      );
    });

    test('empresa inactiva ya en /login: se queda (null)', () {
      expect(resolveRedirect(guard(companyInactive: true), '/login'), isNull);
    });

    test('needsOnboarding fuera de /onboarding: redirige a /onboarding', () {
      expect(resolveRedirect(guard(onboarding: true), '/dashboard'), '/onboarding');
    });

    test('needsOnboarding en /onboarding: se queda (null)', () {
      expect(resolveRedirect(guard(onboarding: true), '/onboarding'), isNull);
    });

    test('logueado (admin) en /onboarding sin necesidades: /dashboard', () {
      expect(
        resolveRedirect(guard(role: UserRole.admin), '/onboarding'),
        '/dashboard',
      );
    });

    test('logueado (employee) en /onboarding sin necesidades: /attendance', () {
      expect(
        resolveRedirect(guard(role: UserRole.employee), '/onboarding'),
        '/attendance',
      );
    });

    test('logueado (employee) en /login: /attendance', () {
      expect(resolveRedirect(guard(role: UserRole.employee), '/login'), '/attendance');
    });

    test('logueado (admin) en /: /dashboard', () {
      expect(resolveRedirect(guard(role: UserRole.admin), '/'), '/dashboard');
    });

    test('logueado (superadmin) en /login: /dashboard', () {
      expect(resolveRedirect(guard(role: UserRole.superadmin), '/login'), '/dashboard');
    });
  });

  group('resolveRedirect — rutas permitidas (sin redirección)', () {
    test('empleado en sus rutas: null', () {
      for (final r in ['/attendance', '/reports', '/profile', '/justificativos']) {
        expect(resolveRedirect(guard(role: UserRole.employee), r), isNull,
            reason: 'empleado debería poder ver $r');
      }
    });

    test('supervisor en /employees, /workplaces, /history, /incidences: null', () {
      for (final r in [
        '/employees',
        '/workplaces',
        '/history',
        '/incidences',
        '/employees/',
        '/workplaces/',
      ]) {
        expect(resolveRedirect(guard(role: UserRole.supervisor), r), isNull,
            reason: 'supervisor debería poder ver $r');
      }
    });

    test('admin en rutas administrativas: null', () {
      for (final r in [
        '/dashboard',
        '/employees',
        '/employees/create',
        '/workplaces',
        '/workplaces/create',
        '/attendance',
        '/history',
        '/medical_documents',
        '/incidences',
        '/incidences/create',
        '/reports',
        '/settings',
      ]) {
        expect(resolveRedirect(guard(role: UserRole.admin), r), isNull,
            reason: 'admin debería poder ver $r');
      }
    });

    test('superadmin en /companies y /settings: null', () {
      for (final r in ['/companies', '/companies/create', '/settings']) {
        expect(resolveRedirect(guard(role: UserRole.superadmin), r), isNull);
      }
    });
  });

  group('resolveRedirect — NEGATIVOS (acceso denegado)', () {
    test('empleado NO puede ir a rutas administrativas', () {
      for (final r in [
        '/dashboard',
        '/companies',
        '/settings',
        '/employees',
        '/employees/create',
        '/workplaces',
        '/workplaces/create',
        '/history',
        '/medical_documents',
        '/incidences',
      ]) {
        expect(resolveRedirect(guard(role: UserRole.employee), r), '/attendance',
            reason: 'empleado no debería ver $r');
      }
    });

    test('supervisor NO puede acceder a acciones administrativas', () {
      for (final r in [
        '/attendance',
        '/settings',
        '/medical_documents',
        '/reports',
        '/reports/2026-01',
      ]) {
        expect(resolveRedirect(guard(role: UserRole.supervisor), r), '/dashboard',
            reason: 'supervisor no debería ver $r');
      }
    });

    test('supervisor NO puede crear/editar empleados ni lugares ni incidencias', () {
      for (final r in [
        '/employees/create',
        '/employees/edit',
        '/workplaces/create',
        '/workplaces/edit',
        '/incidences/create',
        '/incidences/edit',
      ]) {
        expect(resolveRedirect(guard(role: UserRole.supervisor), r), '/dashboard',
            reason: 'supervisor no debería acceder a $r');
      }
    });

    test('supervisor en /history (solo lectura) SÍ está permitido', () {
      expect(resolveRedirect(guard(role: UserRole.supervisor), '/history'), isNull);
    });

    test('supervisor en /incidences (solo lectura) SÍ está permitido', () {
      expect(resolveRedirect(guard(role: UserRole.supervisor), '/incidences'), isNull);
      expect(
        resolveRedirect(guard(role: UserRole.supervisor), '/incidences/abc'),
        isNull,
      );
    });

    test('empleado logueado en /login: redirige a su home /attendance', () {
      expect(resolveRedirect(guard(role: UserRole.employee), '/login'), '/attendance');
    });
  });
}