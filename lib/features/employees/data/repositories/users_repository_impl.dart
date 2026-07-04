import '../../../../core/services/firestore_service.dart';
import '../../../authentication/data/services/auth_service.dart';
import '../../../authentication/data/models/user_model.dart';
import '../../domain/repositories/users_repository.dart';

class UsersRepositoryImpl implements UsersRepository {
  final FirestoreService _firestoreService;
  final AuthService _authService;

  UsersRepositoryImpl(this._firestoreService, this._authService);

  @override
  Stream<List<UserModel>> getUsers() {
    return _firestoreService.collectionStream<UserModel>(
      path: 'users',
      fromJson: UserModel.fromJson,
    );
  }

  @override
  Future<void> createUser(UserModel user, String password) async {
    final credential = await _authService.register(
      email: user.email,
      password: password,
    );

    final uid = credential.user!.uid;
    final firebaseUser = credential.user!;

    final newUser = user.copyWith(id: uid, createdAt: DateTime.now());

    try {
      await _firestoreService.setDocument(
        path: 'users',
        documentId: uid,
        data: newUser.toJson(),
      );
    } catch (e) {
      await _authService.deleteUser(firebaseUser);
      rethrow;
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
}