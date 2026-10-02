import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/models/company_model.dart';
import '../../../../core/router/app_routes.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/widgets/widgets.dart';
import '../providers/company_action_provider.dart';
import 'register_payment_dialog.dart';

class CompanyCard extends ConsumerWidget {
  final CompanyModel company;

  const CompanyCard({super.key, required this.company});

  Future<void> _confirmToggleCompany(
    BuildContext context,
    WidgetRef ref,
  ) async {
    final isActive = company.estado == CompanyEstado.activa;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.cardDark,
        title: Text(isActive ? 'Desactivar empresa' : 'Activar empresa',
            style: const TextStyle(color: AppColors.textWhite)),
        content: Text(
          isActive
              ? 'Todos los usuarios de esta empresa no podrán iniciar sesión mientras esté inactiva. ¿Deseas continuar?'
              : 'Los usuarios de esta empresa podrán volver a iniciar sesión. ¿Deseas continuar?',
          style: const TextStyle(color: AppColors.textMuted),
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppTheme.radiusXl),
          side: BorderSide(color: AppColors.gold.withValues(alpha: 0.18)),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Cancelar',
                style: TextStyle(color: AppColors.textMuted)),
          ),
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            style: TextButton.styleFrom(
                foregroundColor:
                    isActive ? AppColors.error : AppColors.success),
            child: Text(isActive ? 'Desactivar' : 'Activar'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;
    await ref.read(toggleCompanyStateProvider.notifier).toggle(company);
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isActive = company.estado == CompanyEstado.activa;
    final isToggling = ref.watch(toggleCompanyStateProvider).isLoading;
    final isMobile = AppTheme.isMobile(context);

    if (isMobile) {
      return AppCard(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
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
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    company.nombreComercial,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textWhite,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
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
            const SizedBox(height: 16),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [
                AppTheme.badge(
                  label: isActive ? 'Activa' : 'Inactiva',
                  bgColor: (isActive ? AppColors.success : AppColors.error)
                      .withValues(alpha: 0.15),
                  textColor: isActive ? AppColors.success : AppColors.error,
                ),
                _SubscriptionInfo(company: company),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
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
                      builder: (_) => RegisterPaymentDialog(company: company),
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
                      : () => _confirmToggleCompany(context, ref),
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
      );
    }

    return AppCard(
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
                        builder: (_) => RegisterPaymentDialog(company: company),
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
                        : () => _confirmToggleCompany(context, ref),
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
    final isTrial = company.lastPaymentAt == null;
    final label = isTrial ? 'Prueba' : company.plan.label;
    final detail = '${_fmtDate(paidUntil)} · ${days}d';

    if (isTrial) {
      return AppTheme.badge(
        label: '$label hasta $detail',
        bgColor: nearExpiry
            ? AppColors.warning.withValues(alpha: 0.15)
            : AppColors.info.withValues(alpha: 0.15),
        textColor: nearExpiry ? AppColors.warning : AppColors.info,
      );
    }

    final Color bg =
        nearExpiry ? AppColors.warning.withValues(alpha: 0.15) : AppColors.gold.withValues(alpha: 0.12);
    final Color fg = nearExpiry ? AppColors.warning : AppColors.gold;

    return Wrap(
      spacing: 6,
      runSpacing: 6,
      crossAxisAlignment: WrapCrossAlignment.center,
      children: [
        AppTheme.badge(
          label: label,
          bgColor: AppColors.cardDark,
          textColor: AppColors.textSecondary,
        ),
        AppTheme.badge(
          label: 'Vence $detail',
          bgColor: bg,
          textColor: fg,
        ),
      ],
    );
  }
}
