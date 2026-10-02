import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/models/company_model.dart';
import '../../../../core/providers/async_action_state.dart';
import '../../../../core/router/app_routes.dart';
import '../../../../core/theme/app_theme.dart';
import '../providers/company_action_provider.dart';
import '../providers/company_providers.dart';
import 'register_payment_dialog.dart';
import 'superadmin_settings_components.dart';

/// Panel de la plataforma para el superadmin (TASK-017): reemplaza la
/// configuración de empresa en la solapa "Configuración", mostrando las
/// métricas de la plataforma, el registro de pagos y su historial.
class SuperadminSettingsPanel extends ConsumerStatefulWidget {
  const SuperadminSettingsPanel({super.key});

  @override
  ConsumerState<SuperadminSettingsPanel> createState() =>
      _SuperadminSettingsPanelState();
}

class _SuperadminSettingsPanelState extends ConsumerState<SuperadminSettingsPanel> {
  CompanyModel? _selectedCompany;

  /// Sincroniza [_selectedCompany] con la instancia más reciente de la lista
  /// usando únicamente [CompanyModel.id] como clave de identidad. Se llama
  /// desde [ref.listen] para no mutar estado dentro del árbol de build.
  void _syncSelection(List<CompanyModel> companies) {
    if (companies.isEmpty) {
      if (_selectedCompany != null) setState(() => _selectedCompany = null);
      return;
    }
    if (_selectedCompany == null) {
      setState(() => _selectedCompany = companies.first);
      return;
    }
    final updated = companies
        .where((c) => c.id == _selectedCompany!.id)
        .toList();
    final next = updated.isNotEmpty ? updated.first : companies.first;
    if (next != _selectedCompany) {
      setState(() => _selectedCompany = next);
    }
  }

  @override
  Widget build(BuildContext context) {
    final metrics = ref.watch(platformMetricsProvider);
    final companiesAsync = ref.watch(allCompaniesProvider);
    final paymentsAsync = ref.watch(recentPaymentsProvider);
    final isMobile = AppTheme.isMobile(context);

    // Reacciona a cada nueva emisión de la lista de empresas y sincroniza
    // la selección por id, fuera del árbol de build.
    ref.listen(allCompaniesProvider, (_, next) {
      _syncSelection(next.value ?? const <CompanyModel>[]);
    });

    // Muestra snackbar de éxito tras un pago registrado y resetea el provider.
    ref.listen<AsyncActionState>(registerPaymentProvider, (prev, next) {
      if (prev?.status != AsyncActionStatus.loading) return;
      if (next.status == AsyncActionStatus.success) {
        ref.read(registerPaymentProvider.notifier).reset();
        ScaffoldMessenger.of(context).showSnackBar(
          AppTheme.successSnackBar('Pago registrado. Empresa habilitada.'),
        );
      }
    });

    final companies = companiesAsync.value ?? const <CompanyModel>[];

    // Inicialización defensiva solo en el primer build cuando el listener
    // aún no tuvo oportunidad de dispararse (estado ya cargado).
    final effectiveSelected = _selectedCompany != null &&
            companies.any((c) => c.id == _selectedCompany!.id)
        ? companies.firstWhere((c) => c.id == _selectedCompany!.id)
        : (companies.isNotEmpty ? companies.first : null);

    return SingleChildScrollView(
      padding: EdgeInsets.all(isMobile ? 16.0 : 24.0),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 720),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  IconButton(
                    icon: const Icon(Icons.arrow_back,
                        color: AppColors.textWhite),
                    tooltip: 'Volver al inicio',
                    // Navegación dentro del ShellRoute: se llega con
                    // context.go, por lo que pop() no tiene nada que
                    // desapilar. (Fase B — A2)
                    onPressed: () => context.go(RoutePaths.dashboard),
                  ),
                  const SizedBox(width: 8),
                  Text('Panel de la plataforma', style: AppTheme.headingLg),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                'Métricas de la plataforma, registro e historial de pagos de las empresas.',
                style: AppTheme.bodyLg,
              ),
              const SizedBox(height: 24),
              Wrap(
                spacing: 10,
                runSpacing: 10,
                children: [
                  SuperadminMetricChip(
                    label: 'Total',
                    value: metrics.total,
                    color: AppColors.gold,
                  ),
                  SuperadminMetricChip(
                    label: 'Activas',
                    value: metrics.activas,
                    color: AppColors.success,
                  ),
                  SuperadminMetricChip(
                    label: 'Suspendidas',
                    value: metrics.suspendidas,
                    color: AppColors.error,
                  ),
                  SuperadminMetricChip(
                    label: 'Por vencer',
                    value: metrics.porVencer,
                    color: AppColors.warning,
                  ),
                  SuperadminMetricChip(
                    label: 'En prueba',
                    value: metrics.enPrueba,
                    color: AppColors.info,
                  ),
                ],
              ),
              const SizedBox(height: 28),
              Text('Registrar pago', style: AppTheme.headingMd),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: InputDecorator(
                      decoration: AppTheme.inputDecoration(
                        label: 'Empresa',
                        icon: Icons.business_outlined,
                      ),
                      child: DropdownButtonHideUnderline(
                        child: DropdownButton<CompanyModel>(
                          value: effectiveSelected,
                          dropdownColor: AppColors.cardDark,
                          style: const TextStyle(color: AppColors.textWhite),
                          isExpanded: true,
                          items: companies
                              .map(
                                (c) => DropdownMenuItem(
                                  value: c,
                                  child: Text(
                                    c.nombreComercial,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                              )
                              .toList(),
                          onChanged: (v) =>
                              setState(() => _selectedCompany = v),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  FilledButton.icon(
                    onPressed: effectiveSelected == null
                        ? null
                        : () => showDialog<void>(
                              context: context,
                              builder: (_) => RegisterPaymentDialog(
                                company: effectiveSelected,
                              ),
                            ),
                    icon: const Icon(Icons.payment, size: 18),
                    label: const Text('Pagar'),
                    style: FilledButton.styleFrom(
                      backgroundColor: AppColors.gold,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 20,
                        vertical: 18,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius:
                            BorderRadius.circular(AppTheme.radiusSm),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 28),
              // ----------------------------------------------------------------
              // Historial de empresa seleccionada (filtrado por companyId)
              // ----------------------------------------------------------------
              if (effectiveSelected != null) ...[
                Row(
                  children: [
                    const Icon(Icons.receipt_long_outlined,
                        color: AppColors.gold, size: 18),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Historial de ${effectiveSelected.nombreComercial}',
                        style: AppTheme.headingMd,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                SuperadminCompanyPaymentsSection(companyId: effectiveSelected.id),
                const SizedBox(height: 28),
              ],
              // ----------------------------------------------------------------
              // Últimos pagos de la plataforma (global, todos los clientes)
              // ----------------------------------------------------------------
              Text('Últimos pagos de la plataforma', style: AppTheme.headingMd),
              const SizedBox(height: 12),
              paymentsAsync.when(
                loading: () =>
                    const Center(child: CircularProgressIndicator()),
                error: (e, _) => Center(
                  child: Column(
                    children: [
                      const Text('No se pudo cargar los pagos recientes',
                          style: TextStyle(color: AppColors.error)),
                      const SizedBox(height: 8),
                      TextButton.icon(
                        onPressed: () => ref.invalidate(recentPaymentsProvider),
                        icon: const Icon(Icons.refresh, size: 16),
                        label: const Text('Reintentar'),
                        style: TextButton.styleFrom(foregroundColor: AppColors.gold),
                      ),
                    ],
                  ),
                ),
                data: (payments) {
                  if (payments.isEmpty) {
                    return AppTheme.emptyState(
                      icon: Icons.receipt_long_outlined,
                      title: 'Sin pagos registrados',
                      subtitle:
                          'Registrá el primer pago desde el panel o desde la solapa Empresas.',
                    );
                  }
                  return Column(
                    children: payments
                        .map((p) => SuperadminPaymentTile(payment: p))
                        .toList(),
                  );
                },
              ),

            ],
          ),
        ),
      ),
    );
  }
}