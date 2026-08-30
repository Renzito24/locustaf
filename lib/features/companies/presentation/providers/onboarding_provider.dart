import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/models/company_model.dart';
import '../../../../core/models/user_model.dart';
import '../../../../core/providers/firebase_providers.dart';
import '../../../authentication/presentation/providers/auth_provider.dart';

class OnboardingState {
  final bool isLoading;
  final String? error;

  const OnboardingState({this.isLoading = false, this.error});

  OnboardingState copyWith({bool? isLoading, String? error}) {
    return OnboardingState(
      isLoading: isLoading ?? this.isLoading,
      error: error,
    );
  }
}

class OnboardingNotifier extends Notifier<OnboardingState> {
  @override
  OnboardingState build() => const OnboardingState();

  /// Crea la empresa y el usuario admin asociado a ella.
  ///
  /// [profile] son los datos personales del usuario (nombre, apellido, dni,
  /// telefono, direccion). [company] son los datos de la empresa.
  Future<void> createCompanyAndAdmin({
    required UserModel profile,
    required CompanyModel company,
  }) async {
    state = const OnboardingState(isLoading: true);

    final authUser = ref.read(authServiceProvider).currentUser;
    if (authUser == null) {
      state = const OnboardingState(error: 'No hay sesión activa.');
      return;
    }

    final firestore = ref.read(firestoreServiceProvider);

    try {
      // Las reglas de Firestore no ven las escrituras pendientes de una misma
      // transacción (una empresa recién creada no existe aún para la regla de
      // alta del usuario admin), por lo que el alta se realiza en dos pasos:
      // 1) crear la empresa; 2) crear el documento del admin. Si falla el
      // segundo paso se elimina la empresa huérfana (permitido por las reglas
      // para el usuario en onboarding que la creó).
      final companyRef = firestore.collection('companies').doc();
      final companyData = company.toJson();
      companyData['id'] = companyRef.id;
      companyData['createdBy'] = authUser.uid;
      await companyRef.set(companyData);

      final user = profile.copyWith(
        id: authUser.uid,
        rol: UserRole.admin,
        companyId: companyRef.id,
        isActive: true,
        isDeleted: false,
        createdAt: DateTime.now(),
      );
      final userRef = firestore.collection('users').doc(authUser.uid);

      try {
        await userRef.set(user.toJson());
      } catch (_) {
        // Limpieza de la empresa huérfana si falló el alta del admin.
        await companyRef.delete();
        rethrow;
      }

      state = const OnboardingState(isLoading: false);
    } catch (e) {
      state = OnboardingState(error: 'Error al crear la empresa: $e');
    }
  }
}

final onboardingProvider =
    NotifierProvider<OnboardingNotifier, OnboardingState>(OnboardingNotifier.new);
