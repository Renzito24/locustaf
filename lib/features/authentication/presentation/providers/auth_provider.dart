import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/services/auth_service.dart';
import '../../data/repositories/auth_repository_impl.dart';

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

/// 5. Provider de usuario actual
final currentUserProvider = Provider<User?>((ref) {
  return FirebaseAuth.instance.currentUser;
});