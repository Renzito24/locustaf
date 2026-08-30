import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';

import '../../../../core/services/firestore_service.dart';
import '../../../../core/models/user_model.dart';
import '../../domain/repositories/users_repository.dart';

class UsersRepositoryImpl implements UsersRepository {
  final FirestoreService _firestoreService;
  final String? _companyId;

  UsersRepositoryImpl(this._firestoreService, {String? companyId})
      : _companyId = companyId;

  @override
  Stream<List<UserModel>> getUsers() {
    if (_companyId == null) return Stream.value(<UserModel>[]);
    return _firestoreService.queryStreamWithFilters<UserModel>(
      path: 'users',
      filters: {'companyId': _companyId},
      fromJson: UserModel.fromJson,
    );
  }

  @override
  Future<void> createUser(UserModel user, String password) async {
    final adminApp = await Firebase.initializeApp(
      name: 'adminCreation',
      options: Firebase.app().options,
    );
    final adminAuth = FirebaseAuth.instanceFor(app: adminApp);

    User? firebaseUser;
    try {
      final result = await adminAuth.createUserWithEmailAndPassword(
        email: user.email,
        password: password,
      );
      firebaseUser = result.user;
      final uid = firebaseUser!.uid;

      final newUser = user.copyWith(
        id: uid,
        createdAt: DateTime.now(),
        companyId: _companyId,
      );
      await _firestoreService.setDocument(
        path: 'users',
        documentId: uid,
        data: newUser.toJson(),
      );
    } catch (e) {
      if (firebaseUser != null) {
        await firebaseUser.delete();
      }
      rethrow;
    } finally {
      await adminAuth.signOut();
      await adminApp.delete();
    }
  }

  @override
  Future<void> updateUser(UserModel user) async {
    await _firestoreService.updateDocument(
      path: 'users',
      documentId: user.id,
      data: user.copyWith(updatedAt: DateTime.now()).toJson(),
    );
  }

  @override
  Future<void> deleteUser(String uid) async {
    await _firestoreService.updateDocument(
      path: 'users',
      documentId: uid,
      data: {
        'isDeleted': true,
        'updatedAt': DateTime.now().toUtc().toIso8601String(),
      },
    );
    // Purgar el lock de asistencia del usuario para liberar el ID y evitar
    // locks huérfanos que bloqueen un futuro re-ingreso.
    await _firestoreService.deleteDocument(
      path: '_attendance_locks',
      documentId: uid,
    );
  }
}