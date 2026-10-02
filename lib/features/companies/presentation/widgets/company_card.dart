import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/models/company_model.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/widgets/widgets.dart';
import '../providers/company_action_provider.dart';
import 'company_card_components.dart';

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
            CompanyHeaderInfo(company: company),
            const SizedBox(height: 16),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [
                CompanyStatusBadge(isActive: isActive),
                SubscriptionInfoBadge(company: company),
              ],
            ),
            const SizedBox(height: 16),
            CompanyActionButtons(
              company: company,
              isActive: isActive,
              isToggling: isToggling,
              onToggle: _confirmToggleCompany,
            ),
          ],
        ),
      );
    }

    return AppCard(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: CompanyHeaderInfoDesktop(company: company),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              CompanyStatusBadge(isActive: isActive),
              const SizedBox(height: 10),
              SubscriptionInfoBadge(company: company),
              const SizedBox(height: 10),
              CompanyActionButtons(
                company: company,
                isActive: isActive,
                isToggling: isToggling,
                onToggle: _confirmToggleCompany,
              ),
            ],
          ),
        ],
      ),
    );
  }
}
