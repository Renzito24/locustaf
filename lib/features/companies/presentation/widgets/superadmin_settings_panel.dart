import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/models/company_model.dart';
import '../../../../core/models/payment_model.dart';
import '../../../../core/providers/async_action_state.dart';
import '../../../../core/router/app_routes.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/widgets/widgets.dart';
import '../providers/company_action_provider.dart';
import '../providers/company_providers.dart';
import 'register_payment_dialog.dart';

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
                  _MetricChip(
                    label: 'Total',
                    value: metrics.total,
                    color: AppColors.gold,
                  ),
                  _MetricChip(
                    label: 'Activas',
                    value: metrics.activas,
                    color: AppColors.success,
                  ),
                  _MetricChip(
                    label: 'Suspendidas',
                    value: metrics.suspendidas,
                    color: AppColors.error,
                  ),
                  _MetricChip(
                    label: 'Por vencer',
                    value: metrics.porVencer,
                    color: AppColors.warning,
                  ),
                  _MetricChip(
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
                _CompanyPaymentsSection(companyId: effectiveSelected.id),
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
                  child: Text('Error al cargar pagos: $e',
                      style: const TextStyle(color: AppColors.error)),
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
                        .map((p) => _PaymentTile(payment: p))
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

class _MetricChip extends StatelessWidget {
  final String label;
  final int value;
  final Color color;

  const _MetricChip({
    required this.label,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return AppCard(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 28,
            height: 28,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: color.withValues(alpha: 0.15),
            ),
            alignment: Alignment.center,
            child: Text(
              '$value',
              style: TextStyle(
                color: color,
                fontWeight: FontWeight.w700,
                fontSize: 13,
              ),
            ),
          ),
          const SizedBox(width: 8),
          Text(
            label,
            style: const TextStyle(
              color: AppColors.textMuted,
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }
}

class _PaymentTile extends StatelessWidget {
  final PaymentModel payment;

  const _PaymentTile({required this.payment});

  String _fmtDate(DateTime d) =>
      '${d.day.toString().padLeft(2, '0')}/${d.month.toString().padLeft(2, '0')}/${d.year}';

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: AppCard(
        padding: const EdgeInsets.all(14),
        child: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: AppColors.gold.withValues(alpha: 0.15),
              ),
              child: const Icon(Icons.payment, color: AppColors.gold, size: 20),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    payment.companyName,
                    style: const TextStyle(
                      color: AppColors.textWhite,
                      fontWeight: FontWeight.w600,
                      fontSize: 14,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    '${payment.plan.label} · Vence ${_fmtDate(payment.paidUntil)} · '
                    '${_fmtDate(payment.createdAt)}',
                    style: const TextStyle(
                      color: AppColors.textMuted,
                      fontSize: 12,
                    ),
                  ),
                  if (payment.nota != null && payment.nota!.isNotEmpty) ...[
                    const SizedBox(height: 2),
                    Text(
                      payment.nota!,
                      style: const TextStyle(
                        color: AppColors.textSecondary,
                        fontSize: 12,
                        fontStyle: FontStyle.italic,
                      ),
                    ),
                  ],
                ],
              ),
            ),
            AppTheme.badge(
              label: payment.plan.label,
              bgColor: AppColors.gold.withValues(alpha: 0.12),
              textColor: AppColors.gold,
            ),
          ],
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Sección de historial de pagos filtrada por empresa seleccionada.
// Usa companyPaymentsProvider (family) que hace la query con el índice
// compuesto (companyId ASC, createdAt DESC) declarado en firestore.indexes.json.
// ---------------------------------------------------------------------------
class _CompanyPaymentsSection extends ConsumerWidget {
  final String companyId;
  const _CompanyPaymentsSection({required this.companyId});

  String _fmtDate(DateTime d) =>
      '${d.day.toString().padLeft(2, '0')}/${d.month.toString().padLeft(2, '0')}/${d.year}';

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final paymentsAsync = ref.watch(companyPaymentsProvider(companyId));
    return paymentsAsync.when(
      loading: () => const Center(
        child: Padding(
          padding: EdgeInsets.symmetric(vertical: 16),
          child: CircularProgressIndicator(),
        ),
      ),
      error: (e, _) => Text(
        'Error al cargar historial: $e',
        style: const TextStyle(color: AppColors.error),
      ),
      data: (payments) {
        if (payments.isEmpty) {
          return AppTheme.emptyState(
            icon: Icons.history,
            title: 'Sin pagos registrados para esta empresa',
            subtitle: 'Registrá el primer pago usando el botón "Pagar".',
          );
        }
        return AppCard(
          padding: const EdgeInsets.all(0),
          child: Column(
            children: [
              // Cabecera de la tabla
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                decoration: BoxDecoration(
                  color: AppColors.bgDarkTop,
                  borderRadius: const BorderRadius.vertical(
                    top: Radius.circular(AppTheme.radiusMd),
                  ),
                ),
                child: const Row(
                  children: [
                    Expanded(
                      flex: 3,
                      child: Text(
                        'Fecha de pago',
                        style: TextStyle(
                          color: AppColors.textSecondary,
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                    Expanded(
                      flex: 2,
                      child: Text(
                        'Plan',
                        style: TextStyle(
                          color: AppColors.textSecondary,
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                    Expanded(
                      flex: 3,
                      child: Text(
                        'Vencimiento',
                        style: TextStyle(
                          color: AppColors.textSecondary,
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                    SizedBox(width: 40), // espacio badge
                  ],
                ),
              ),
              const Divider(height: 1, color: Color(0x1AFFFFFF)),
              // Filas
              ...payments.asMap().entries.map((entry) {
                final i = entry.key;
                final p = entry.value;
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Padding(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 14, vertical: 10),
                      child: Row(
                        children: [
                          Expanded(
                            flex: 3,
                            child: Text(
                              _fmtDate(p.createdAt),
                              style: const TextStyle(
                                color: AppColors.textWhite,
                                fontSize: 13,
                              ),
                            ),
                          ),
                          Expanded(
                            flex: 2,
                            child: Text(
                              p.plan.label,
                              style: const TextStyle(
                                color: AppColors.textWhite,
                                fontSize: 13,
                              ),
                            ),
                          ),
                          Expanded(
                            flex: 3,
                            child: Text(
                              _fmtDate(p.paidUntil),
                              style: const TextStyle(
                                color: AppColors.gold,
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                          SizedBox(
                            width: 40,
                            child: p.nota != null && p.nota!.isNotEmpty
                                ? Tooltip(
                                    message: p.nota!,
                                    child: const Icon(
                                      Icons.sticky_note_2_outlined,
                                      size: 16,
                                      color: AppColors.textMuted,
                                    ),
                                  )
                                : const SizedBox.shrink(),
                          ),
                        ],
                      ),
                    ),
                    if (i < payments.length - 1)
                      const Divider(height: 1, color: Color(0x1AFFFFFF)),
                  ],
                );
              }),
            ],
          ),
        );
      },
    );
  }
}