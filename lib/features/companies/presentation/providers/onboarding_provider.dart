import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/models/company_model.dart';
import '../../../../core/models/user_model.dart';
import '../../../../core/providers/firebase_providers.dart';
import '../../../authentication/presentation/providers/auth_provider.dart';
import 'company_providers.dart';

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

    final companyRepo = ref.read(companyRepositoryProvider);
    final firestore = ref.read(firestoreServiceProvider);

    try {
      // 1. Crear la empresa
      final companyId = await companyRepo.createCompany(company);

      // 2. Crear el usuario admin con companyId
      final user = profile.copyWith(
        id: authUser.uid,
        rol: UserRole.admin,
        companyId: companyId,
        isActive: true,
        isDeleted: false,
        createdAt: DateTime.now(),
      );
      await firestore.setDocument(
        path: 'users',
        documentId: authUser.uid,
        data: user.toJson(),
      );

      state = const OnboardingState(isLoading: false);
    } catch (e) {
      state = OnboardingState(error: 'Error al crear la empresa: $e');
    }
  }
}

final onboardingProvider =
    NotifierProvider<OnboardingNotifier, OnboardingState>(OnboardingNotifier.new);
