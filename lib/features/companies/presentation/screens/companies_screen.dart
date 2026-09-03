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
          else
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
              const SizedBox(height: 12),
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
