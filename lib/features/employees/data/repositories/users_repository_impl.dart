import '../../../../core/services/firestore_service.dart';
import '../../../authentication/data/models/user_model.dart';
import '../../domain/repositories/users_repository.dart';

class UsersRepositoryImpl implements UsersRepository {
  final FirestoreService _firestoreService;

  UsersRepositoryImpl(this._firestoreService);

  @override
  Stream<List<UserModel>> getUsers() {
    return _firestoreService.collectionStream<UserModel>(
      path: 'users',
      fromJson: UserModel.fromJson,
    );
  }

  @override
  Future<void> createUser(UserModel user, String password) async {
    throw UnimplementedError();
  }
}