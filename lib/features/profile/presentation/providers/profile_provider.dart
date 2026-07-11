import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/providers/firebase_providers.dart';

class ProfileUpdateState {
  final bool isLoading;
  final String? error;
  final String? success;

  const ProfileUpdateState({
    this.isLoading = false,
    this.error,
    this.success,
  });

  const ProfileUpdateState.idle() : this();
  const ProfileUpdateState.loading() : this(isLoading: true);
  const ProfileUpdateState.success(String msg) : this(success: msg);
  const ProfileUpdateState.error(String msg) : this(error: msg);
}

class ProfileUpdateNotifier extends Notifier<ProfileUpdateState> {
  @override
  ProfileUpdateState build() => const ProfileUpdateState.idle();

  Future<void> updateProfile({
    required String userId,
    required String nombre,
    required String apellido,
    String? telefono,
  }) async {
    state = const ProfileUpdateState.loading();
    try {
      final svc = ref.read(firestoreServiceProvider);
      await svc.updateDocument(
        path: 'users',
        documentId: userId,
        data: {
          'nombre': nombre,
          'apellido': apellido,
          'telefono': telefono,
          'updatedAt': DateTime.now().toIso8601String(),
        },
      );
      state = const ProfileUpdateState.success('Perfil actualizado correctamente.');
    } catch (e) {
      state = ProfileUpdateState.error('Error al actualizar perfil: $e');
    }
  }

  void reset() {
    state = const ProfileUpdateState.idle();
  }
}

final profileUpdateProvider = NotifierProvider<ProfileUpdateNotifier, ProfileUpdateState>(
  ProfileUpdateNotifier.new,
);

class PasswordChangeState {
  final bool isLoading;
  final String? error;
  final String? success;

  const PasswordChangeState({
    this.isLoading = false,
    this.error,
    this.success,
  });

  const PasswordChangeState.idle() : this();
  const PasswordChangeState.loading() : this(isLoading: true);
  const PasswordChangeState.success(String msg) : this(success: msg);
  const PasswordChangeState.error(String msg) : this(error: msg);
}

class PasswordChangeNotifier extends Notifier<PasswordChangeState> {
  @override
  PasswordChangeState build() => const PasswordChangeState.idle();

  Future<void> changePassword({
    required String currentPassword,
    required String newPassword,
  }) async {
    state = const PasswordChangeState.loading();
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null || user.email == null) {
        state = const PasswordChangeState.error('No hay usuario autenticado.');
        return;
      }

      final credential = EmailAuthProvider.credential(
        email: user.email!,
        password: currentPassword,
      );

      await user.reauthenticateWithCredential(credential);
      await user.updatePassword(newPassword);

      state = const PasswordChangeState.success('Contraseña actualizada correctamente.');
    } on FirebaseAuthException catch (e) {
      String msg;
      switch (e.code) {
        case 'wrong-password':
          msg = 'La contraseña actual es incorrecta.';
          case 'weak-password':
          msg = 'La nueva contraseña es demasiado débil.';
          default:
          msg = 'Error al cambiar contraseña: ${e.message}';
      }
      state = PasswordChangeState.error(msg);
    } catch (e) {
      state = PasswordChangeState.error('Error al cambiar contraseña: $e');
    }
  }

  void reset() {
    state = const PasswordChangeState.idle();
  }
}

final passwordChangeProvider = NotifierProvider<PasswordChangeNotifier, PasswordChangeState>(
  PasswordChangeNotifier.new,
);
