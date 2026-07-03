import '../../../../features/authentication/data/models/user_model.dart';

abstract class UsersRepository {
  Stream<List<UserModel>> getUsers();
}
