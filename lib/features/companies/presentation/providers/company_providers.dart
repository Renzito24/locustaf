import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/models/company_model.dart';
import '../../../../core/models/user_model.dart';
import '../../../../core/providers/data_providers.dart';
import '../../../../core/providers/firebase_providers.dart';
import '../../../authentication/presentation/providers/auth_provider.dart';
import '../../data/repositories/company_repository_impl.dart';
import '../../domain/repositories/company_repository.dart';
import '../../domain/services/platform_metrics.dart';

final companyRepositoryProvider = Provider<CompanyRepository>((ref) {
  final svc = ref.read(firestoreServiceProvider);
  return CompanyRepositoryImpl(svc);
});

/// Empresa actual del usuario autenticado (null si no tiene empresa).
final currentCompanyProvider = StreamProvider<CompanyModel?>((ref) {
  final companyId = ref.watch(currentCompanyIdProvider);
  if (companyId == null) return Stream.value(null);
  final repo = ref.read(companyRepositoryProvider);
  return repo.getCompany(companyId);
});

/// Indica si el usuario autenticado es superadmin (plataforma).
final isSuperadminProvider = Provider<bool>((ref) {
  return ref.watch(currentAppUserProvider).value?.rol == UserRole.superadmin;
});

/// Todas las empresas de la plataforma (solo superadmin).
final allCompaniesProvider = StreamProvider<List<CompanyModel>>((ref) {
  final repo = ref.read(companyRepositoryProvider);
  return repo.getAllCompanies();
});

/// Métricas de la plataforma derivadas de [allCompaniesProvider].
final platformMetricsProvider = Provider<PlatformMetrics>((ref) {
  final companies = ref.watch(allCompaniesProvider).value ?? const [];
  return computePlatformMetrics(companies, DateTime.now());
});
