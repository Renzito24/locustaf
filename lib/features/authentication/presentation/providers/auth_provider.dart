import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/models/user_model.dart';
import '../../data/services/auth_service.dart';
import '../../data/repositories/auth_repository_impl.dart';
import '../../../../core/services/firestore_service.dart';

/// 1. Provider de FirebaseAuth
final firebaseAuthProvider = Provider<FirebaseAuth>((ref) {
  return FirebaseAuth.instance;
});

/// 2. Provider del service
final authServiceProvider = Provider<AuthService>((ref) {
  final firebaseAuth = ref.read(firebaseAuthProvider);
  return AuthService(firebaseAuth);
});

/// 3. Provider del repository
final authRepositoryProvider = Provider<AuthRepositoryImpl>((ref) {
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

/// 6. Provider del documento Firestore del usuario autenticado
final currentAppUserProvider = StreamProvider<UserModel?>((ref) {
  final authUser = ref.watch(authStateProvider).value;
  if (authUser == null) {
    return Stream.value(null);
  }
  final svc = FirestoreService(FirebaseFirestore.instance);
  return svc.documentStream<UserModel>(
    path: 'users',
    documentId: authUser.uid,
    fromJson: UserModel.fromJson,
  );
});

/// 7. Provider del rol del usuario autenticado
final userRoleProvider = Provider<UserRole?>((ref) {
  return ref.watch(currentAppUserProvider).value?.rol;
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