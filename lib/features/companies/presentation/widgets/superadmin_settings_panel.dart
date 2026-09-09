import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/models/company_model.dart';
import '../../../../core/models/payment_model.dart';
import '../../../../core/theme/app_theme.dart';
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

  @override
  Widget build(BuildContext context) {
    final metrics = ref.watch(platformMetricsProvider);
    final companiesAsync = ref.watch(allCompaniesProvider);
    final paymentsAsync = ref.watch(recentPaymentsProvider);
    final isMobile = AppTheme.isMobile(context);

    final companies = companiesAsync.value ?? const <CompanyModel>[];
    if (_selectedCompany == null && companies.isNotEmpty) {
      _selectedCompany = companies.first;
    }

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
                    tooltip: 'Volver',
                    onPressed: () => context.pop(),
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
                    child: DropdownButtonFormField<CompanyModel>(
                      initialValue: _selectedCompany,
                      decoration: AppTheme.inputDecoration(
                        label: 'Empresa',
                        icon: Icons.business_outlined,
                      ),
                      dropdownColor: AppColors.cardDark,
                      style: const TextStyle(color: AppColors.textWhite),
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
                  const SizedBox(width: 12),
                  FilledButton.icon(
                    onPressed: _selectedCompany == null
                        ? null
                        : () => showDialog<void>(
                              context: context,
                              builder: (_) => RegisterPaymentDialog(
                                company: _selectedCompany!,
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
              Text('Historial de pagos', style: AppTheme.headingMd),
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
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: AppTheme.cardDecoration(),
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
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: AppTheme.cardDecoration(),
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
    );
  }
}