import '../../../../core/models/company_model.dart';

abstract class CompanyRepository {
  Stream<CompanyModel?> getCompany(String companyId);
  Stream<List<CompanyModel>> getAllCompanies();
  Future<CompanyModel?> getCompanyOnce(String companyId);
  Future<String> createCompany(CompanyModel company);
  Future<void> updateCompany(CompanyModel company);
  Future<void> setEstado(String companyId, CompanyEstado estado);

  /// Registra un pago manual (solo superadmin): fija hasta cuándo queda
  /// habilitada la empresa y la modalidad del plan (TASK-011), y deja un
  /// registro permanente de pagos en `payments/` (TASK-017). Ambas escrituras
  /// se realizan atómicamente en un mismo batch.
  Future<void> registerPayment(
    String companyId, {
    required DateTime paidUntil,
    CompanyPlan plan = CompanyPlan.mensual,
    String? nota,
  });
}
