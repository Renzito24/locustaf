import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/models/company_model.dart';
import '../../../../core/theme/app_theme.dart';
import '../providers/company_providers.dart';

class CompaniesScreen extends ConsumerWidget {
  const CompaniesScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isSuperadmin = ref.watch(isSuperadminProvider);
    final companiesAsync = ref.watch(allCompaniesProvider);
    final isMobile = AppTheme.isMobile(context);

    return Padding(
      padding: EdgeInsets.all(isMobile ? 16.0 : 24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Empresas', style: AppTheme.headingLg),
          const SizedBox(height: 4),
          Text(
            'Administración de empresas de la plataforma.',
            style: AppTheme.bodyLg,
          ),
          const SizedBox(height: 24),
          if (!isSuperadmin)
            const Expanded(
              child: Center(
                child: Text(
                  'Solo el super administrador puede ver esta sección.',
                  style: TextStyle(color: AppColors.textMuted),
                ),
              ),
            )
          else
            Expanded(
              child: companiesAsync.when(
                loading: () => const Center(child: CircularProgressIndicator()),
                error: (e, _) => Center(
                  child: Text('Error al cargar empresas: $e',
                      style: const TextStyle(color: AppColors.error)),
                ),
                data: (companies) {
                  if (companies.isEmpty) {
                    return const Center(
                      child: Text('No hay empresas registradas.',
                          style: TextStyle(color: AppColors.textMuted)),
                    );
                  }
                  return ListView.separated(
                    itemCount: companies.length,
                    separatorBuilder: (_, _) => const SizedBox(height: 12),
                    itemBuilder: (context, index) {
                      final company = companies[index];
                      return _CompanyCard(company: company);
                    },
                  );
                },
              ),
            ),
        ],
      ),
    );
  }
}

class _CompanyCard extends StatelessWidget {
  final CompanyModel company;

  const _CompanyCard({required this.company});

  @override
  Widget build(BuildContext context) {
    final isActive = company.estado == CompanyEstado.activa;
    return Container(
      decoration: AppTheme.cardDecoration(),
      padding: const EdgeInsets.all(20),
      child: Row(
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
                if (company.email != null)
                  Text(
                    company.email!,
                    style: const TextStyle(color: AppColors.textMuted, fontSize: 13),
                  ),
              ],
            ),
          ),
          AppTheme.badge(
            label: isActive ? 'Activa' : 'Inactiva',
            bgColor: (isActive ? AppColors.success : AppColors.error)
                .withValues(alpha: 0.15),
            textColor: isActive ? AppColors.success : AppColors.error,
          ),
        ],
      ),
    );
  }
}
