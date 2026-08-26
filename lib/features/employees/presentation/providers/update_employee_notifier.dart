import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/models/user_model.dart';
import 'users_provider.dart';

class UpdateEmployeeNotifier extends AsyncNotifier<void> {
  @override
  Future<void> build() => Future.value();

  Future<void> updateEmployee(UserModel user) async {
    state = const AsyncLoading();
    final repo = ref.read(usersRepositoryProvider);
    try {
      await repo.updateUser(user);
      state = const AsyncData(null);
    } catch (e, st) {
      state = AsyncError(e, st);
    }
  }

  void reset() {
    state = const AsyncData(null);
  }
}

final updateEmployeeProvider =
    AsyncNotifierProvider<UpdateEmployeeNotifier, void>(
  UpdateEmployeeNotifier.new,
);