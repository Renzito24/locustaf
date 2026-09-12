import '../models/user_model.dart';

/// Estado inmutable que el guard de rutas necesita para decidir.
///
/// Separado de `AuthStateListenable` para que la lógica de redirección sea
/// una función pura y testeable sin FirebaseAuth ni go_router.
class RouteGuardState {
  final bool isLoggedIn;
  final bool isUserBlocked;
  final bool isCompanyInactive;
  final bool needsOnboarding;
  final UserRole? role;
  final bool isEmployee;

  const RouteGuardState({
    required this.isLoggedIn,
    required this.isUserBlocked,
    required this.isCompanyInactive,
    required this.needsOnboarding,
    required this.role,
    required this.isEmployee,
  });
}

/// Devuelve el redirect a aplicar (o null si la ruta puede continuar).
///
/// Espejo exacto de la lógica del guard de `AppRouter`; no ejecutar nunca
/// aquí lógica de negocio de Firestore.
String? resolveRedirect(RouteGuardState s, String location) {
  final goingToLogin = location == '/login';
  final goingToSplash = location == '/';

  if (!s.isLoggedIn) {
    return goingToLogin ? null : '/login';
  }

  // Usuario autenticado con cuenta bloqueada (desactivada o eliminada):
  // forzar el login con mensaje de bloqueado.
  if (s.isLoggedIn && s.isUserBlocked) {
    return goingToLogin ? null : '/login?blocked=true';
  }

  // Empresa del usuario inactiva: bloquear el acceso a la app.
  if (s.isLoggedIn && s.isCompanyInactive) {
    return goingToLogin ? null : '/login?company=inactive';
  }

  // Autenticado pero sin empresa: debe completar el onboarding.
  if (s.isLoggedIn && s.needsOnboarding) {
    final goingToOnboarding = location == '/onboarding';
    return goingToOnboarding ? null : '/onboarding';
  }

  // Ya no necesita onboarding y está ahí: salir hacia la home del rol.
  if (s.isLoggedIn && location == '/onboarding') {
    return s.isEmployee ? '/attendance' : '/dashboard';
  }

  final role = s.role;

  // Autenticado en /login o splash: ir a la home del rol.
  if (s.isLoggedIn && (goingToLogin || goingToSplash)) {
    return role == UserRole.employee ? '/attendance' : '/dashboard';
  }

  final path = location;

  // Empleado: solo sus rutas permitidas.
  if (role == UserRole.employee) {
    const allowed = ['/attendance', '/reports', '/profile', '/justificativos'];
    if (!allowed.any((r) => path.startsWith(r)) &&
        path != '/' &&
        !path.startsWith('/login')) {
      return '/attendance';
    }
  }

  // Supervisor: rutas administrativas restringidas.
  if (role == UserRole.supervisor) {
    const restricted = [
      '/attendance',
      '/settings',
      '/medical_documents',
      '/reports',
      '/employees/create',
      '/employees/edit',
      '/workplaces/create',
      '/workplaces/edit',
      '/incidences/create',
      '/incidences/edit',
    ];
    if (restricted.any((r) => path.startsWith(r))) {
      return '/dashboard';
    }
  }

  return null;
}