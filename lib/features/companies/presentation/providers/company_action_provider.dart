import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/models/company_model.dart';
import 'company_providers.dart';

class CompanyFormData {
  final String nombreComercial;
  final String razonSocial;
  final String cuit;
  final String? direccion;
  final String? telefono;
  final String? email;
  final CompanyEstado estado;

  const CompanyFormData({
    required this.nombreComercial,
    required this.razonSocial,
    required this.cuit,
    this.direccion,
    this.telefono,
    this.email,
    this.estado = CompanyEstado.activa,
  });
}

class CreateCompanyNotifier extends AsyncNotifier<void> {
  @override
  Future<void> build() => Future.value();

  Future<void> createCompany(CompanyFormData data) async {
    state = const AsyncLoading();
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
      );
      await repo.createCompany(company);
      state = const AsyncData(null);
    } catch (e, st) {
      state = AsyncError(e, st);
    }
  }

  void reset() {
    state = const AsyncData(null);
  }
}

class UpdateCompanyNotifier extends AsyncNotifier<void> {
  @override
  Future<void> build() => Future.value();

  Future<void> updateCompany(CompanyModel company, CompanyFormData data) async {
    state = const AsyncLoading();
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
      );
      await repo.updateCompany(updated);
      state = const AsyncData(null);
    } catch (e, st) {
      state = AsyncError(e, st);
    }
  }

  void reset() {
    state = const AsyncData(null);
  }
}

class ToggleCompanyStateNotifier extends AsyncNotifier<void> {
  @override
  Future<void> build() => Future.value();

  Future<void> toggle(CompanyModel company) async {
    state = const AsyncLoading();
    final repo = ref.read(companyRepositoryProvider);
    try {
      final newEstado = company.estado == CompanyEstado.activa
          ? CompanyEstado.inactiva
          : CompanyEstado.activa;
      await repo.setEstado(company.id, newEstado);
      state = const AsyncData(null);
    } catch (e, st) {
      state = AsyncError(e, st);
    }
  }

  void reset() {
    state = const AsyncData(null);
  }
}

final createCompanyProvider = AsyncNotifierProvider<CreateCompanyNotifier, void>(
  CreateCompanyNotifier.new,
);

final updateCompanyProvider = AsyncNotifierProvider<UpdateCompanyNotifier, void>(
  UpdateCompanyNotifier.new,
);

final toggleCompanyStateProvider = AsyncNotifierProvider<ToggleCompanyStateNotifier, void>(
  ToggleCompanyStateNotifier.new,
);
