import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/providers/async_action_state.dart';
import '../../../../core/router/app_routes.dart';
import '../../../../core/theme/app_theme.dart';
import '../providers/company_action_provider.dart';
import '../providers/company_providers.dart';
import '../widgets/company_card.dart';
import '../widgets/platform_metrics_row.dart';

class CompaniesScreen extends ConsumerWidget {
  const CompaniesScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isSuperadmin = ref.watch(isSuperadminProvider);
    final companiesAsync = ref.watch(allCompaniesProvider);
    final isMobile = AppTheme.isMobile(context);

    ref.listen<AsyncActionState>(toggleCompanyStateProvider, (prev, next) {
      if (prev?.status != AsyncActionStatus.loading) return;
      if (next.status == AsyncActionStatus.success) {
        ref.read(toggleCompanyStateProvider.notifier).reset();
        ScaffoldMessenger.of(context).showSnackBar(
          AppTheme.successSnackBar('Estado de la empresa actualizado'),
        );
      } else if (next.status == AsyncActionStatus.failure) {
        ScaffoldMessenger.of(context).showSnackBar(
          AppTheme.errorSnackBar('Error al actualizar el estado: ${next.error}'),
        );
      }
    });

    ref.listen<AsyncActionState>(registerPaymentProvider, (prev, next) {
      if (prev?.status != AsyncActionStatus.loading) return;
      if (next.status == AsyncActionStatus.success) {
        ref.read(registerPaymentProvider.notifier).reset();
        ScaffoldMessenger.of(context).showSnackBar(
          AppTheme.successSnackBar('Pago registrado correctamente'),
        );
      } else if (next.status == AsyncActionStatus.failure) {
        ScaffoldMessenger.of(context).showSnackBar(
          AppTheme.errorSnackBar('Error al registrar el pago: ${next.error}'),
        );
      }
    });

    return SafeArea(
      child: SingleChildScrollView(
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
              const PlatformMetricsRow(),
              const SizedBox(height: 24),
              companiesAsync.when(
                loading: () => const Center(child: CircularProgressIndicator()),
                error: (e, _) => Center(
                  child: Column(
                    children: [
                      const Text('No se pudieron cargar las empresas',
                          style: TextStyle(color: AppColors.error)),
                      const SizedBox(height: 8),
                      TextButton.icon(
                        onPressed: () => ref.invalidate(allCompaniesProvider),
                        icon: const Icon(Icons.refresh, size: 16),
                        label: const Text('Reintentar'),
                        style: TextButton.styleFrom(foregroundColor: AppColors.gold),
                      ),
                    ],
                  ),
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
                      return CompanyCard(company: company);
                    },
                  );
                },
              ),
            ],
          ],
        ),
      ),
    );
  }
}

