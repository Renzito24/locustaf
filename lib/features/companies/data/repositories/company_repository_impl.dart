import '../../../../core/models/company_model.dart';
import '../../../../core/services/firestore_service.dart';
import '../../domain/repositories/company_repository.dart';

class CompanyRepositoryImpl implements CompanyRepository {
  final FirestoreService _firestoreService;

  CompanyRepositoryImpl(this._firestoreService);

  @override
  Stream<CompanyModel?> getCompany(String companyId) {
    return _firestoreService.documentStream<CompanyModel>(
      path: 'companies',
      documentId: companyId,
      fromJson: CompanyModel.fromJson,
    );
  }

  @override
  Stream<List<CompanyModel>> getAllCompanies() {
    return _firestoreService.collectionStream<CompanyModel>(
      path: 'companies',
      fromJson: CompanyModel.fromJson,
    );
  }

  @override
  Future<CompanyModel?> getCompanyOnce(String companyId) async {
    final data = await _firestoreService.getDocument(
      path: 'companies',
      documentId: companyId,
    );
    if (data == null) return null;
    return CompanyModel.fromJson(data);
  }

  @override
  Future<String> createCompany(CompanyModel company) async {
    // addDocument ya incluye el id generado en el documento, por lo que no
    // es necesario realizar un update posterior. Esto evita errores de
    // permisos durante el onboarding, cuando el usuario aún no tiene rol.
    final id = await _firestoreService.addDocument(
      path: 'companies',
      data: company.toJson(),
    );
    return id;
  }

  @override
  Future<void> updateCompany(CompanyModel company) async {
    await _firestoreService.updateDocument(
      path: 'companies',
      documentId: company.id,
      data: company.copyWith(updatedAt: DateTime.now()).toJson(),
    );
  }

  @override
  Future<void> setEstado(String companyId, CompanyEstado estado) async {
    await _firestoreService.updateDocument(
      path: 'companies',
      documentId: companyId,
      data: {
        'estado': estado.name,
        'updatedAt': DateTime.now().toUtc().toIso8601String(),
      },
    );
  }

  @override
  Future<void> registerPayment(
    String companyId, {
    required DateTime paidUntil,
    CompanyPlan plan = CompanyPlan.mensual,
  }) async {
    await _firestoreService.updateDocument(
      path: 'companies',
      documentId: companyId,
      data: {
        'paidUntil': paidUntil.toUtc().toIso8601String(),
        'lastPaymentAt': DateTime.now().toUtc().toIso8601String(),
        'plan': plan.name,
        'updatedAt': DateTime.now().toUtc().toIso8601String(),
      },
    );
  }
}
