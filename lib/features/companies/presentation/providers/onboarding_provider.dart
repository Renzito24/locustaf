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
      // Crear la empresa y el usuario admin en una única transacción para
      // evitar empresas huérfanas si falla la creación del usuario.
      await firestore.runTransaction<String>((transaction) async {
        final companyRef = firestore.collection('companies').doc();
        final companyData = company.toJson();
        companyData['id'] = companyRef.id;
        transaction.set(companyRef, companyData);

        final user = profile.copyWith(
          id: authUser.uid,
          rol: UserRole.admin,
          companyId: companyRef.id,
          isActive: true,
          isDeleted: false,
          createdAt: DateTime.now(),
        );
        final userRef = firestore.collection('users').doc(authUser.uid);
        transaction.set(userRef, user.toJson());

        return companyRef.id;
      });

      state = const OnboardingState(isLoading: false);
    } catch (e) {
      state = OnboardingState(error: 'Error al crear la empresa: $e');
    }
  }
}

final onboardingProvider =
    NotifierProvider<OnboardingNotifier, OnboardingState>(OnboardingNotifier.new);
