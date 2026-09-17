import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/providers/async_action_state.dart';
import 'users_provider.dart';

class DeleteEmployeeNotifier extends Notifier<AsyncActionState> {
  @override
  AsyncActionState build() => const AsyncActionState.idle();

  Future<void> deleteEmployee(String uid) async {
    state = const AsyncActionState.loading();
    final repo = ref.read(usersRepositoryProvider);
    try {
      await repo.deleteUser(uid);
      state = const AsyncActionState.success();
    } catch (e) {
      state = AsyncActionState.failure(e);
    }
  }

  void reset() {
    state = const AsyncActionState.idle();
  }
}

final deleteEmployeeProvider = NotifierProvider<DeleteEmployeeNotifier, AsyncActionState>(
  DeleteEmployeeNotifier.new,
);