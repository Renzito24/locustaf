import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/models/company_model.dart';
import '../../../../core/theme/app_theme.dart';
import '../providers/company_action_provider.dart';
import '../widgets/company_form.dart';

class CompanyFormScreen extends ConsumerStatefulWidget {
  final CompanyModel? company;

  const CompanyFormScreen({super.key, this.company});

  @override
  ConsumerState<CompanyFormScreen> createState() => _CompanyFormScreenState();
}

class _CompanyFormScreenState extends ConsumerState<CompanyFormScreen> {
  @override
  Widget build(BuildContext context) {
    final isEditing = widget.company != null;
    final provider = isEditing ? updateCompanyProvider : createCompanyProvider;
    final state = ref.watch(provider);

    ref.listen<AsyncValue<void>>(provider, (prev, next) {
      next.whenOrNull(
        data: (_) {
          if (context.mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              AppTheme.successSnackBar(
                isEditing ? 'Empresa actualizada' : 'Empresa creada',
              ),
            );
            context.pop();
          }
        },
        error: (error, _) {
          ScaffoldMessenger.of(context).showSnackBar(
            AppTheme.errorSnackBar('Error: $error'),
          );
        },
      );
    });

    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 600),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  IconButton(
                    icon: const Icon(Icons.arrow_back, color: AppColors.textWhite),
                    tooltip: 'Volver',
                    onPressed: () => context.pop(),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    isEditing ? 'Editar empresa' : 'Nueva empresa',
                    style: AppTheme.headingMd,
                  ),
                ],
              ),
              const SizedBox(height: 24),
              Text(
                isEditing
                    ? 'Modificá los datos de la empresa.'
                    : 'Completá los datos para crear una nueva empresa.',
                style: AppTheme.bodyLg,
              ),
              const SizedBox(height: 24),
              CompanyForm(
                existingCompany: widget.company,
                isLoading: state.isLoading,
                errorMessage: state.error?.toString(),
                onSubmit: (data) async {
                  if (isEditing) {
                    await ref.read(updateCompanyProvider.notifier).updateCompany(widget.company!, data);
                  } else {
                    await ref.read(createCompanyProvider.notifier).createCompany(data);
                  }
                },
              ),
              const SizedBox(height: 12),
              Center(
                child: TextButton(
                  onPressed: () => context.pop(),
                  child: const Text('Cancelar y volver al listado'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
