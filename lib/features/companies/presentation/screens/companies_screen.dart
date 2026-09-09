import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/models/company_model.dart';
import '../../../../core/router/app_routes.dart';
import '../../../../core/theme/app_theme.dart';
import '../providers/company_action_provider.dart';
import '../providers/company_providers.dart';

class CompaniesScreen extends ConsumerWidget {
  const CompaniesScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isSuperadmin = ref.watch(isSuperadminProvider);
    final companiesAsync = ref.watch(allCompaniesProvider);
    final isMobile = AppTheme.isMobile(context);

    ref.listen<AsyncValue<void>>(toggleCompanyStateProvider, (prev, next) {
      next.whenOrNull(
        data: (_) {
          ref.read(toggleCompanyStateProvider.notifier).reset();
          ScaffoldMessenger.of(context).showSnackBar(
            AppTheme.successSnackBar('Estado de la empresa actualizado'),
          );
        },
        error: (error, _) {
          ScaffoldMessenger.of(context).showSnackBar(
            AppTheme.errorSnackBar('Error al actualizar el estado: $error'),
          );
        },
      );
    });

    ref.listen<AsyncValue<void>>(registerPaymentProvider, (prev, next) {
      next.whenOrNull(
        data: (_) {
          ref.read(registerPaymentProvider.notifier).reset();
          ScaffoldMessenger.of(context).showSnackBar(
            AppTheme.successSnackBar('Pago registrado correctamente'),
          );
        },
        error: (error, _) {
          ScaffoldMessenger.of(context).showSnackBar(
            AppTheme.errorSnackBar('Error al registrar el pago: $error'),
          );
        },
      );
    });

    return SingleChildScrollView(
      padding: EdgeInsets.all(isMobile ? 16.0 : 24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              IconButton(
                icon: const Icon(Icons.arrow_back, color: AppColors.textWhite),
                tooltip: 'Volver al dashboard',
                onPressed: () => context.go(RoutePaths.dashboard),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Empresas', style: AppTheme.headingLg),
                    const SizedBox(height: 4),
                    Text(
                      'Administración de empresas de la plataforma.',
                      style: AppTheme.bodyLg,
                    ),
                  ],
                ),
              ),
              if (isSuperadmin)
                FilledButton.icon(
                  onPressed: () => context.push(RoutePaths.createCompany),
                  icon: const Icon(Icons.add_business_outlined, size: 18),
                  label: const Text('Nueva empresa'),
                  style: FilledButton.styleFrom(
                    backgroundColor: AppColors.gold,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(AppTheme.radiusSm)),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 24),
          if (!isSuperadmin)
            const Center(
              child: Text(
                'Solo el super administrador puede ver esta sección.',
                style: TextStyle(color: AppColors.textMuted),
              ),
            )
          else ...[
            const _PlatformMetricsRow(),
            const SizedBox(height: 24),
            companiesAsync.when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (e, _) => Center(
                child: Text('Error al cargar empresas: $e',
                    style: const TextStyle(color: AppColors.error)),
              ),
              data: (companies) {
                if (companies.isEmpty) {
                  return AppTheme.emptyState(
                    icon: Icons.business_outlined,
                    title: 'No hay empresas registradas',
                    subtitle: 'Creá la primera empresa para comenzar.',
                  );
                }
                return ListView.separated(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: companies.length,
                  separatorBuilder: (_, _) => const SizedBox(height: 12),
                  itemBuilder: (context, index) {
                    final company = companies[index];
                    return _CompanyCard(company: company);
                  },
                );
              },
            ),
          ],
        ],
      ),
    );
  }
}

/// Tarjetas resumen de la plataforma (TASK-011): total, activas, suspendidas,
/// próximas a vencer y en prueba.
class _PlatformMetricsRow extends ConsumerWidget {
  const _PlatformMetricsRow();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final metrics = ref.watch(platformMetricsProvider);
    final isMobile = AppTheme.isMobile(context);

    final cards = <_MetricCardData>[
      _MetricCardData(
        label: 'Total',
        value: metrics.total,
        icon: Icons.business_outlined,
        color: AppColors.gold,
      ),
      _MetricCardData(
        label: 'Activas',
        value: metrics.activas,
        icon: Icons.check_circle_outline,
        color: AppColors.success,
      ),
      _MetricCardData(
        label: 'Suspendidas',
        value: metrics.suspendidas,
        icon: Icons.block_outlined,
        color: AppColors.error,
      ),
      _MetricCardData(
        label: 'Próximas a vencer',
        value: metrics.porVencer,
        icon: Icons.event_outlined,
        color: AppColors.warning,
      ),
      _MetricCardData(
        label: 'En prueba',
        value: metrics.enPrueba,
        icon: Icons.science_outlined,
        color: AppColors.info,
      ),
    ];

    return Wrap(
      spacing: 12,
      runSpacing: 12,
      children: cards.map((c) => _MetricCard(data: c, isMobile: isMobile)).toList(),
    );
  }
}

class _MetricCardData {
  final String label;
  final int value;
  final IconData icon;
  final Color color;

  const _MetricCardData({
    required this.label,
    required this.value,
    required this.icon,
    required this.color,
  });
}

class _MetricCard extends StatelessWidget {
  final _MetricCardData data;
  final bool isMobile;

  const _MetricCard({required this.data, required this.isMobile});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: isMobile ? (MediaQuery.sizeOf(context).width - 32) / 2 - 6 : 200,
      padding: const EdgeInsets.all(16),
      decoration: AppTheme.cardDecoration(),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: data.color.withValues(alpha: 0.15),
            ),
            child: Icon(data.icon, color: data.color, size: 20),
          ),
          const SizedBox(width: 12),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '${data.value}',
                style: const TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textWhite,
                ),
              ),
              Text(
                data.label,
                style: const TextStyle(
                  color: AppColors.textMuted,
                  fontSize: 12,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _CompanyCard extends ConsumerWidget {
  final CompanyModel company;

  const _CompanyCard({required this.company});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isActive = company.estado == CompanyEstado.activa;
    final isToggling = ref.watch(toggleCompanyStateProvider).isLoading;

    return Container(
      decoration: AppTheme.cardDecoration(),
      padding: const EdgeInsets.all(20),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: AppColors.gold.withValues(alpha: 0.15),
            ),
            child: const Icon(Icons.business, color: AppColors.gold, size: 22),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  company.nombreComercial,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textWhite,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'CUIT: ${company.cuit}',
                  style: const TextStyle(color: AppColors.textMuted, fontSize: 13),
                ),
                if (company.razonSocial.isNotEmpty)
                  Text(
                    company.razonSocial,
                    style: const TextStyle(color: AppColors.textMuted, fontSize: 13),
                  ),
                if (company.email != null)
                  Text(
                    company.email!,
                    style: const TextStyle(color: AppColors.textMuted, fontSize: 13),
                  ),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              AppTheme.badge(
                label: isActive ? 'Activa' : 'Inactiva',
                bgColor: (isActive ? AppColors.success : AppColors.error)
                    .withValues(alpha: 0.15),
                textColor: isActive ? AppColors.success : AppColors.error,
              ),
              const SizedBox(height: 10),
              _SubscriptionInfo(company: company),
              const SizedBox(height: 10),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  IconButton(
                    onPressed: () => context.push(
                      RoutePaths.editCompany,
                      extra: company,
                    ),
                    icon: const Icon(Icons.edit_outlined, size: 18),
                    color: AppColors.gold,
                    tooltip: 'Editar',
                    visualDensity: VisualDensity.compact,
                  ),
                  IconButton(
                    onPressed: () {
                      showDialog<void>(
                        context: context,
                        builder: (_) => _RegisterPaymentDialog(company: company),
                      );
                    },
                    icon: const Icon(Icons.payment, size: 18),
                    color: AppColors.gold,
                    tooltip: 'Registrar pago',
                    visualDensity: VisualDensity.compact,
                  ),
                  IconButton(
                    onPressed: isToggling
                        ? null
                        : () => ref.read(toggleCompanyStateProvider.notifier).toggle(company),
                    icon: Icon(
                      isActive ? Icons.block_outlined : Icons.check_circle_outlined,
                      size: 18,
                    ),
                    color: isActive ? AppColors.error : AppColors.success,
                    tooltip: isActive ? 'Desactivar' : 'Activar',
                    visualDensity: VisualDensity.compact,
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Subscription info chips shown in each company card (TASK-011)
// ---------------------------------------------------------------------------
class _SubscriptionInfo extends StatelessWidget {
  final CompanyModel company;
  const _SubscriptionInfo({required this.company});

  String _fmtDate(DateTime d) =>
      '${d.day.toString().padLeft(2, '0')}/${d.month.toString().padLeft(2, '0')}/${d.year}';

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final usable = company.isUsableAt(now);
    final paidUntil = company.paidUntil;

    if (!usable) {
      return AppTheme.badge(
        label: 'Vencida',
        bgColor: AppColors.error.withValues(alpha: 0.15),
        textColor: AppColors.error,
      );
    }

    if (paidUntil == null) {
      return AppTheme.badge(
        label: 'En prueba',
        bgColor: AppColors.info.withValues(alpha: 0.15),
        textColor: AppColors.info,
      );
    }

    final days = company.daysRemainingAt(now);
    final nearExpiry = days <= 7;
    final label = 'Vence ${_fmtDate(paidUntil)}';
    final Color bg =
        nearExpiry ? AppColors.warning.withValues(alpha: 0.15) : AppColors.gold.withValues(alpha: 0.12);
    final Color fg = nearExpiry ? AppColors.warning : AppColors.gold;

    return Wrap(
      spacing: 6,
      runSpacing: 6,
      crossAxisAlignment: WrapCrossAlignment.center,
      children: [
        AppTheme.badge(
          label: company.plan.label,
          bgColor: AppColors.cardDark,
          textColor: AppColors.textSecondary,
        ),
        AppTheme.badge(
          label: '$label · ${days}d restantes',
          bgColor: bg,
          textColor: fg,
        ),
      ],
    );
  }
}

// ---------------------------------------------------------------------------
// Dialog to register a manual payment (TASK-011)
// ---------------------------------------------------------------------------
enum _PaymentType { mes, anio, custom }

class _RegisterPaymentDialog extends ConsumerStatefulWidget {
  final CompanyModel company;
  const _RegisterPaymentDialog({required this.company});

  @override
  ConsumerState<_RegisterPaymentDialog> createState() => _RegisterPaymentDialogState();
}

class _RegisterPaymentDialogState extends ConsumerState<_RegisterPaymentDialog> {
  late CompanyPlan _plan;
  _PaymentType _type = _PaymentType.mes;
  DateTime? _customDate;

  @override
  void initState() {
    super.initState();
    _plan = widget.company.plan;
  }

  DateTime _baseDate() {
    final now = DateTime.now();
    final current = widget.company.paidUntil;
    return (current != null && current.isAfter(now)) ? current : now;
  }

  DateTime _computePaidUntil() {
    final base = _baseDate();
    switch (_type) {
      case _PaymentType.mes:
        return DateTime(base.year, base.month + 1, base.day);
      case _PaymentType.anio:
        return DateTime(base.year + 1, base.month, base.day);
      case _PaymentType.custom:
        return _customDate ?? base;
    }
  }

  String _fmtDate(DateTime d) =>
      '${d.day.toString().padLeft(2, '0')}/${d.month.toString().padLeft(2, '0')}/${d.year}';

  void _submit() {
    final paidUntil = _type == _PaymentType.custom ? _customDate : _computePaidUntil();
    if (paidUntil == null) return;
    ref.read(registerPaymentProvider.notifier).registerPayment(
          widget.company.id,
          paidUntil: paidUntil,
          plan: _plan,
        );
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final preview = _computePaidUntil();
    return AlertDialog(
      backgroundColor: AppColors.cardDark,
      title: const Text('Registrar pago',
          style: TextStyle(color: AppColors.textWhite)),
      content: SizedBox(
        width: 340,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            DropdownButtonFormField<CompanyPlan>(
              initialValue: _plan,
              decoration: AppTheme.inputDecoration(
                label: 'Plan',
                icon: Icons.credit_card_outlined,
              ),
              dropdownColor: AppColors.cardDark,
              style: const TextStyle(color: AppColors.textWhite),
              items: CompanyPlan.values
                  .map((p) => DropdownMenuItem(value: p, child: Text(p.label)))
                  .toList(),
              onChanged: (v) => setState(() => _plan = v ?? CompanyPlan.mensual),
            ),
            const SizedBox(height: 16),
            const Text('Extender período',
                style: TextStyle(color: AppColors.textSecondary, fontSize: 12)),
            const SizedBox(height: 8),
            SegmentedButton<_PaymentType>(
              selected: {_type},
              onSelectionChanged: (v) => setState(() {
                _type = v.first;
                _customDate = null;
              }),
              segments: const [
                ButtonSegment(value: _PaymentType.mes, label: Text('+1 mes')),
                ButtonSegment(value: _PaymentType.anio, label: Text('+1 año')),
                ButtonSegment(value: _PaymentType.custom, label: Text('Fecha')),
              ],
            ),
            if (_type == _PaymentType.custom) ...[
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  onPressed: () async {
                    final picked = await showDatePicker(
                      context: context,
                      initialDate: _customDate ?? DateTime.now(),
                      firstDate: DateTime.now(),
                      lastDate: DateTime.now().add(const Duration(days: 3650)),
                      locale: const Locale('es'),
                    );
                    if (picked != null) setState(() => _customDate = picked);
                  },
                  icon: const Icon(Icons.calendar_today, size: 16),
                  label: Text(
                    _customDate == null ? 'Elegir fecha' : _fmtDate(_customDate!),
                    style: const TextStyle(color: AppColors.textWhite),
                  ),
                  style: OutlinedButton.styleFrom(
                    side: const BorderSide(color: AppColors.textSecondary),
                    foregroundColor: AppColors.textWhite,
                  ),
                ),
              ),
            ],
            const SizedBox(height: 16),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.bgDarkTop,
                borderRadius: BorderRadius.circular(AppTheme.radiusSm),
              ),
              child: Text(
                'Nuevo paidUntil: ${_fmtDate(preview)}',
                style: const TextStyle(
                  color: AppColors.gold,
                  fontWeight: FontWeight.w600,
                  fontSize: 13,
                ),
              ),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancelar',
              style: TextStyle(color: AppColors.textMuted)),
        ),
        FilledButton(
          style: FilledButton.styleFrom(backgroundColor: AppColors.gold),
          onPressed: _submit,
          child: const Text('Registrar'),
        ),
      ],
    );
  }
}
