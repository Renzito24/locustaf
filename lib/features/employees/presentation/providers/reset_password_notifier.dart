import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/providers/async_action_state.dart';
import '../../../authentication/presentation/providers/auth_provider.dart';

class ResetPasswordNotifier extends Notifier<AsyncActionState> {
  @override
  AsyncActionState build() => const AsyncActionState.idle();

  Future<void> resetPassword(String email) async {
    state = const AsyncActionState.loading();
    final authService = ref.read(authServiceProvider);
    try {
      await authService.sendPasswordReset(email);
      state = const AsyncActionState.success();
    } catch (e) {
      state = AsyncActionState.failure(e);
    }
  }

  void reset() {
    state = const AsyncActionState.idle();
  }
}

final resetPasswordProvider = NotifierProvider<ResetPasswordNotifier, AsyncActionState>(
  ResetPasswordNotifier.new,
);