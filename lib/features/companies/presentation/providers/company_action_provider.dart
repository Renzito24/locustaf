import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/models/company_model.dart';
import '../../../../core/providers/async_action_state.dart';
import 'company_providers.dart';

class CompanyFormData {
  final String nombreComercial;
  final String razonSocial;
  final String cuit;
  final String? direccion;
  final String? telefono;
  final String? email;
  final CompanyEstado estado;
  final int toleranciaCheckIn;
  final List<int> diasLaborables;

  const CompanyFormData({
    required this.nombreComercial,
    required this.razonSocial,
    required this.cuit,
    this.direccion,
    this.telefono,
    this.email,
    this.estado = CompanyEstado.activa,
    this.toleranciaCheckIn = 15,
    this.diasLaborables = const [1, 2, 3, 4, 5],
  });
}

class CreateCompanyNotifier extends Notifier<AsyncActionState> {
  @override
  AsyncActionState build() => const AsyncActionState.idle();

  Future<void> createCompany(CompanyFormData data) async {
    state = const AsyncActionState.loading();
    final repo = ref.read(companyRepositoryProvider);
    try {
      final company = CompanyModel(
        id: '',
        nombreComercial: data.nombreComercial,
        razonSocial: data.razonSocial,
        cuit: data.cuit,
        direccion: data.direccion,
        telefono: data.telefono,
        email: data.email,
        estado: data.estado,
        createdAt: DateTime.now(),
        toleranciaCheckIn: data.toleranciaCheckIn,
        diasLaborables: data.diasLaborables,
      );
      await repo.createCompany(company);
      state = const AsyncActionState.success();
    } catch (e) {
      state = AsyncActionState.failure(e);
    }
  }

  void reset() {
    state = const AsyncActionState.idle();
  }
}

class UpdateCompanyNotifier extends Notifier<AsyncActionState> {
  @override
  AsyncActionState build() => const AsyncActionState.idle();

  Future<void> updateCompany(CompanyModel company, CompanyFormData data) async {
    state = const AsyncActionState.loading();
    final repo = ref.read(companyRepositoryProvider);
    try {
      final updated = company.copyWith(
        nombreComercial: data.nombreComercial,
        razonSocial: data.razonSocial,
        cuit: data.cuit,
        direccion: data.direccion,
        telefono: data.telefono,
        email: data.email,
        estado: data.estado,
        updatedAt: DateTime.now(),
        toleranciaCheckIn: data.toleranciaCheckIn,
        diasLaborables: data.diasLaborables,
      );
      await repo.updateCompany(updated);
      state = const AsyncActionState.success();
    } catch (e) {
      state = AsyncActionState.failure(e);
    }
  }

  void reset() {
    state = const AsyncActionState.idle();
  }
}

class ToggleCompanyStateNotifier extends Notifier<AsyncActionState> {
  @override
  AsyncActionState build() => const AsyncActionState.idle();

  Future<void> toggle(CompanyModel company) async {
    state = const AsyncActionState.loading();
    final repo = ref.read(companyRepositoryProvider);
    try {
      final newEstado = company.estado == CompanyEstado.activa
          ? CompanyEstado.inactiva
          : CompanyEstado.activa;
      await repo.setEstado(company.id, newEstado);
      state = const AsyncActionState.success();
    } catch (e) {
      state = AsyncActionState.failure(e);
    }
  }

  void reset() {
    state = const AsyncActionState.idle();
  }
}

class RegisterPaymentNotifier extends Notifier<AsyncActionState> {
  @override
  AsyncActionState build() => const AsyncActionState.idle();

  /// Registra un pago manual y extiende el uso de la empresa hasta [paidUntil]
  /// (TASK-011), dejando el registro en el historial con una [nota] opcional
  /// (TASK-017). Solo el superadmin invoca esta acción desde la UI.
  Future<void> registerPayment(
    String companyId, {
    required DateTime paidUntil,
    CompanyPlan plan = CompanyPlan.mensual,
    String? nota,
  }) async {
    state = const AsyncActionState.loading();
    final repo = ref.read(companyRepositoryProvider);
    try {
      await repo.registerPayment(
        companyId,
        paidUntil: paidUntil,
        plan: plan,
        nota: nota,
      );
      state = const AsyncActionState.success();
    } catch (e) {
      state = AsyncActionState.failure(e);
    }
  }

  void reset() {
    state = const AsyncActionState.idle();
  }
}

final createCompanyProvider = NotifierProvider<CreateCompanyNotifier, AsyncActionState>(
  CreateCompanyNotifier.new,
);

final updateCompanyProvider = NotifierProvider<UpdateCompanyNotifier, AsyncActionState>(
  UpdateCompanyNotifier.new,
);

final toggleCompanyStateProvider = NotifierProvider<ToggleCompanyStateNotifier, AsyncActionState>(
  ToggleCompanyStateNotifier.new,
);

final registerPaymentProvider = NotifierProvider<RegisterPaymentNotifier, AsyncActionState>(
  RegisterPaymentNotifier.new,
);
