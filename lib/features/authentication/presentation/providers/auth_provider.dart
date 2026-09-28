import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/models/user_model.dart';
import '../../../../core/router/app_router.dart';
import '../../application/auth_state_listenable.dart';
import '../../data/services/auth_service.dart';
import '../../data/repositories/auth_repository_impl.dart';
import '../../domain/repositories/auth_repository.dart';

/// Estado inmutable de la sesión.
class SessionState {
  final bool isLoading;
  final UserModel? user;
  final String? companyId;
  final UserRole? role;
  final String? userId;
  final bool isUserBlocked;
  final bool isCompanyInactive;
  final bool needsOnboarding;

  const SessionState({
    required this.isLoading,
    this.user,
    this.companyId,
    this.role,
    this.userId,
    this.isUserBlocked = false,
    this.isCompanyInactive = false,
    this.needsOnboarding = false,
  });

  factory SessionState.fromAuth(AuthStateListenable auth) {
    return SessionState(
      isLoading: auth.isProfileLoading,
      user: auth.userModel,
      companyId: auth.companyId,
      role: auth.role,
      userId: auth.user?.uid,
      isUserBlocked: auth.isUserBlocked,
      isCompanyInactive: auth.isCompanyInactive,
      needsOnboarding: auth.needsOnboarding,
    );
  }
}

class SessionNotifier extends Notifier<SessionState> {
  @override
  SessionState build() {
    ref.keepAlive();
    final auth = AppRouter.auth;
    void listener() {
      state = SessionState.fromAuth(auth);
    }
    auth.addListener(listener);
    ref.onDispose(() {
      auth.removeListener(listener);
    });
    return SessionState.fromAuth(auth);
  }
}

/// 0. Provider raíz de sesión (keepAlive).
///
/// Comparte la misma instancia `AuthStateListenable` utilizada por `AppRouter`
/// para garantizar consistencia total entre la navegación de GoRouter y el
/// árbol de providers de Riverpod.
final sessionProvider = NotifierProvider<SessionNotifier, SessionState>(
  SessionNotifier.new,
);

/// 1. Provider de FirebaseAuth
final firebaseAuthProvider = Provider<FirebaseAuth>((ref) {
  return FirebaseAuth.instance;
});

/// 2. Provider del service
final authServiceProvider = Provider<AuthService>((ref) {
  final firebaseAuth = ref.read(firebaseAuthProvider);
  return AuthService(firebaseAuth);
});

/// 3. Provider del repository (tipado contra la interfaz para permitir
///    fakes en tests sin instanciar FirebaseAuth).
final authRepositoryProvider = Provider<AuthRepository>((ref) {
  final service = ref.read(authServiceProvider);
  return AuthRepositoryImpl(service);
});

/// 4. Stream de estado de autenticación (MUY IMPORTANTE)
final authStateProvider = StreamProvider<User?>((ref) {
  final repo = ref.read(authRepositoryProvider);
  return repo.authStateChanges();
});

/// 5. Provider de usuario actual (Firebase Auth)
final currentUserProvider = Provider<User?>((ref) {
  return FirebaseAuth.instance.currentUser;
});

/// 5b. Provider del uid del usuario autenticado.
///
/// Seam de testeabilidad: lee directamente de la sesión ya resuelta.
final currentUserIdProvider = Provider<String?>((ref) {
  return ref.watch(sessionProvider).userId;
});

/// 6. Provider del modelo de usuario desde la sesión ya resuelta.
final currentUserModelProvider = Provider<UserModel?>((ref) {
  return ref.watch(sessionProvider).user;
});

/// StreamProvider para compatibilidad con código existente y tests que esperan `AsyncValue<UserModel?>`.
final currentAppUserProvider = StreamProvider<UserModel?>((ref) {
  final user = ref.watch(currentUserModelProvider);
  return Stream.value(user);
});

/// 7. Provider del rol del usuario autenticado (leído sincrónicamente de la sesión).
final userRoleProvider = Provider<UserRole?>((ref) {
  return ref.watch(sessionProvider).role;
});

/// 8. Helpers booleanos para role checks
final isAdminProvider = Provider<bool>((ref) {
  return ref.watch(userRoleProvider) == UserRole.admin;
});

final isSupervisorProvider = Provider<bool>((ref) {
  return ref.watch(userRoleProvider) == UserRole.supervisor;
});

final isEmployeeProvider = Provider<bool>((ref) {
  return ref.watch(userRoleProvider) == UserRole.employee;
});

final logoutProvider = Provider<Future<void> Function()>((ref) {
  final service = ref.read(authServiceProvider);
  return service.logout;
});