import 'package:firebase_auth/firebase_auth.dart';

import '../../domain/repositories/auth_repository.dart';
import '../services/auth_service.dart';

class AuthRepositoryImpl implements AuthRepository {
  final AuthService _authService;

  AuthRepositoryImpl(this._authService);

  @override
  Future<UserCredential> login(String email, String password) {
    return _authService.login(email, password);
  }

  @override
  Future<UserCredential?> loginWithGoogle() {
    return _authService.loginWithGoogle();
  }

  @override
  Future<void> logout() {
    return _authService.logout();
  }

  @override
  User? getCurrentUser() {
    return _authService.currentUser;
  }

  @override
  Stream<User?> authStateChanges() {
    return _authService.authStateChanges;
  }

  @override
  Future<void> sendPasswordReset(String email) {
    return _authService.sendPasswordReset(email);
  }
}