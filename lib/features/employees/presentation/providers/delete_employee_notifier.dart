import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'users_provider.dart';

class DeleteEmployeeNotifier extends AsyncNotifier<void> {
  @override
  Future<void> build() => Future.value();

  Future<void> deleteEmployee(String uid) async {
    state = const AsyncLoading();
    final repo = ref.read(usersRepositoryProvider);
    try {
      await repo.deleteUser(uid);
      state = const AsyncData(null);
    } catch (e, st) {
      state = AsyncError(e, st);
    }
  }

  void reset() {
    state = const AsyncData(null);
  }
}

final deleteEmployeeProvider =
    AsyncNotifierProvider<DeleteEmployeeNotifier, void>(
  DeleteEmployeeNotifier.new,
);