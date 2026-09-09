import '../../../../../core/models/company_model.dart';

/// Métricas de la plataforma (solo superadmin). Calculadas en dominio puro
/// para ser testeables sin Firebase (TASK-011).
class PlatformMetrics {
  final int total;
  final int activas;
  final int suspendidas;
  final int porVencer;
  final int enPrueba;

  const PlatformMetrics({
    required this.total,
    required this.activas,
    required this.suspendidas,
    required this.porVencer,
    required this.enPrueba,
  });
}

/// Compute métricas a partir de la lista de empresas. Se usa like de
/// ventana para "próximas a vencer": dentro de los próximos 7 días.
PlatformMetrics computePlatformMetrics(List<CompanyModel> companies, DateTime now) {
  var activas = 0;
  var suspendidas = 0;
  var porVencer = 0;
  var enPrueba = 0;

  for (final company in companies) {
    final usable = company.isUsableAt(now);
    if (!usable) {
      suspendidas++;
      continue;
    }
    activas++;
    final paidUntil = company.paidUntil;
    if (paidUntil == null) {
      enPrueba++;
      continue;
    }
    final diff = paidUntil.difference(now);
    if (!paidUntil.isAfter(now)) {
      continue;
    }
    if (diff.inDays <= 7) porVencer++;
  }

  return PlatformMetrics(
    total: companies.length,
    activas: activas,
    suspendidas: suspendidas,
    porVencer: porVencer,
    enPrueba: enPrueba,
  );
}