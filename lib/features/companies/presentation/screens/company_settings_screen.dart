import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/theme/app_theme.dart';
import '../providers/company_action_provider.dart';
import '../providers/company_providers.dart';
import '../widgets/company_form.dart';
import '../widgets/superadmin_settings_panel.dart';

class CompanySettingsScreen extends ConsumerWidget {
  const CompanySettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isSuperadmin = ref.watch(isSuperadminProvider);
    if (isSuperadmin) {
      return const SuperadminSettingsPanel();
    }

    final companyAsync = ref.watch(currentCompanyProvider);
    final state = ref.watch(updateCompanyProvider);
    final isMobile = AppTheme.isMobile(context);

    ref.listen<AsyncValue<void>>(updateCompanyProvider, (prev, next) {
      next.whenOrNull(
        data: (_) {
          ref.read(updateCompanyProvider.notifier).reset();
          if (context.mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              AppTheme.successSnackBar('Configuración guardada'),
            );
          }
        },
        error: (error, _) {
          if (context.mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              AppTheme.errorSnackBar('Error: $error'),
            );
          }
        },
      );
    });

    return Padding(
      padding: EdgeInsets.all(isMobile ? 16.0 : 24.0),
      child: SingleChildScrollView(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 600),
            child: companyAsync.when(
              loading: () =>
                  const Center(child: CircularProgressIndicator()),
              error: (e, _) => Center(
                child: Text('Error al cargar la empresa: $e',
                    style: const TextStyle(color: AppColors.error)),
              ),
              data: (company) {
                if (company == null) {
                  return Center(
                    child: Text(
                      'No tenés una empresa asignada. Contactá al super administrador.',
                      style: const TextStyle(color: AppColors.textMuted),
                      textAlign: TextAlign.center,
                    ),
                  );
                }
                return Column(
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
                        Text('Configuración', style: AppTheme.headingLg),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Configurá la tolerancia de check-in y los días laborables de ${company.nombreComercial}.',
                      style: AppTheme.bodyLg,
                    ),
                    const SizedBox(height: 24),
                    CompanyForm(
                      existingCompany: company,
                      isLoading: state.isLoading,
                      errorMessage: state.error?.toString(),
                      onSubmit: (data) async {
                        await ref
                            .read(updateCompanyProvider.notifier)
                            .updateCompany(company, data);
                      },
                    ),
                  ],
                );
              },
            ),
          ),
        ),
      ),
    );
  }
}