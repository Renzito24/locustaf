import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/providers/data_providers.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../authentication/presentation/providers/auth_provider.dart';
import '../../../incidences/data/models/incidence_model.dart';
import '../../../incidences/presentation/providers/incidences_provider.dart';
import '../../../incidences/presentation/widgets/incidence_form.dart';

class EmployeeCreateIncidenceScreen extends ConsumerWidget {
  const EmployeeCreateIncidenceScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final createState = ref.watch(incidenceCreateProvider);
    final userId = ref.watch(currentUserIdProvider);

    return Scaffold(
      backgroundColor: AppColors.bgDarkTop,
      appBar: AppBar(
        backgroundColor: AppColors.bgDarkTop,
        title: Text('Nueva incidencia', style: AppTheme.headingMd),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: AppColors.textWhite),
          onPressed: () => context.pop(),
        ),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Container(color: AppColors.gold.withValues(alpha: 0.15)),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 600),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Completá los datos de tu incidencia. Quedará pendiente de aprobación.',
                style: AppTheme.bodyLg,
              ),
              const SizedBox(height: 24),
              IncidenceForm(
                fixedUserId: userId,
                isLoading: createState.isLoading,
                errorMessage: createState.error?.toString(),
                onSubmit: (data) async {
                  final incidence = IncidenceModel(
                    id: '',
                    userId: data.userId,
                    type: data.type,
                    fechaInicio: data.fechaInicio,
                    fechaFin: data.fechaFin,
                    observaciones: data.observaciones,
                    documentoRelacionado: data.documentoRelacionado,
                    estado: IncidenceEstado.pendiente,
                    companyId: ref.read(currentCompanyIdProvider),
                    createdAt: DateTime.now(),
                  );
                  await ref.read(incidenceCreateProvider.notifier).createIncidence(incidence);
                  if (context.mounted) {
                    ref.read(incidenceCreateProvider.notifier).reset();
                    context.pop();
                  }
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}
