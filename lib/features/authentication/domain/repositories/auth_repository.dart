// TODO: Define AuthRepository interface
import 'package:firebase_auth/firebase_auth.dart';

abstract class AuthRepository {
  Future<UserCredential> login(String email, String password);
  Future<void> logout();
  User? getCurrentUser();
  Stream<User?> authStateChanges();
}