import '../../../../core/models/company_model.dart';

abstract class CompanyRepository {
  Stream<CompanyModel?> getCompany(String companyId);
  Stream<List<CompanyModel>> getAllCompanies();
  Future<CompanyModel?> getCompanyOnce(String companyId);
  Future<String> createCompany(CompanyModel company);
  Future<void> updateCompany(CompanyModel company);
  Future<void> setEstado(String companyId, CompanyEstado estado);
}
