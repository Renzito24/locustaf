import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../authentication/data/models/user_model.dart';
import '../../../../core/services/firestore_service.dart';
import '../../data/repositories/users_repository_impl.dart';
import '../../domain/repositories/users_repository.dart';

final firebaseFirestoreProvider = Provider<FirebaseFirestore>((ref) {
  return FirebaseFirestore.instance;
});

final firestoreServiceProvider = Provider<FirestoreService>((ref) {
  final firestore = ref.read(firebaseFirestoreProvider);
  return FirestoreService(firestore);
});

final usersRepositoryProvider = Provider<UsersRepository>((ref) {
  final service = ref.read(firestoreServiceProvider);
  return UsersRepositoryImpl(service);
});

final usersStreamProvider = StreamProvider<List<UserModel>>((ref) {
  final repo = ref.read(usersRepositoryProvider);
  return repo.getUsers();
});
