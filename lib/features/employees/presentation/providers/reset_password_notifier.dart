import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../authentication/presentation/providers/auth_provider.dart';

class ResetPasswordNotifier extends AsyncNotifier<void> {
  @override
  Future<void> build() => Future.value();

  Future<void> resetPassword(String email) async {
    state = const AsyncLoading();
    final authService = ref.read(authServiceProvider);
    try {
      await authService.sendPasswordReset(email);
      state = const AsyncData(null);
    } catch (e, st) {
      state = AsyncError(e, st);
    }
  }

  void reset() {
    state = const AsyncData(null);
  }
}

final resetPasswordProvider =
    AsyncNotifierProvider<ResetPasswordNotifier, void>(
  ResetPasswordNotifier.new,
);
