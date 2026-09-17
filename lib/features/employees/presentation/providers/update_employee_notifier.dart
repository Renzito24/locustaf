import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/models/user_model.dart';
import '../../../../core/providers/async_action_state.dart';
import 'users_provider.dart';

class UpdateEmployeeNotifier extends Notifier<AsyncActionState> {
  @override
  AsyncActionState build() => const AsyncActionState.idle();

  Future<void> updateEmployee(UserModel user) async {
    state = const AsyncActionState.loading();
    final repo = ref.read(usersRepositoryProvider);
    try {
      await repo.updateUser(user);
      state = const AsyncActionState.success();
    } catch (e) {
      state = AsyncActionState.failure(e);
    }
  }

  void reset() {
    state = const AsyncActionState.idle();
  }
}

final updateEmployeeProvider = NotifierProvider<UpdateEmployeeNotifier, AsyncActionState>(
  UpdateEmployeeNotifier.new,
);