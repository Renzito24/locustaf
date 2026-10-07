import '../models/user_model.dart';

/// Estado inmutable que el guard de rutas necesita para decidir.
///
/// Separado de `AuthStateListenable` para que la lógica de redirección sea
/// una función pura y testeable sin FirebaseAuth ni go_router.
class RouteGuardState {
  final bool isLoggedIn;
  final bool isProfileLoading;
  final bool hasProfileError;
  final bool isUserBlocked;
  final bool isCompanyInactive;
  final bool needsOnboarding;
  final UserRole? role;
  final bool isEmployee;

  const RouteGuardState({
    required this.isLoggedIn,
    required this.isProfileLoading,
    this.hasProfileError = false,
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

  // Perfil del usuario aún no leído o con error al cargar:
  // el estado de rol/empresa/bloqueo es desconocido. Permanecer en el splash
  // para mostrar el spinner o la tarjeta de error con opción de reintentar/cerrar sesión.
  if (s.isProfileLoading || s.hasProfileError) {
    return goingToSplash ? null : '/';
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
    return s.isEmployee ? '/principal' : '/dashboard';
  }

  final role = s.role;

  // Autenticado en /login o splash: ir a la home del rol.
  if (s.isLoggedIn && (goingToLogin || goingToSplash)) {
    return role == UserRole.employee ? '/principal' : '/dashboard';
  }

  final path = location;

  // Empleado: solo sus rutas permitidas.
  if (role == UserRole.employee) {
    const allowed = [
      '/principal',
      '/attendance',
      '/history',
      '/reports',
      '/justificativos',
      '/profile',
      '/comunicados',
      '/mis_recibos',
    ];
    if (!allowed.any((r) => path.startsWith(r)) &&
        path != '/' &&
        !path.startsWith('/login')) {
      return '/principal';
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
