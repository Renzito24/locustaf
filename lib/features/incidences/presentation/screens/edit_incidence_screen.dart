import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/theme/app_theme.dart';
import '../../data/models/incidence_model.dart';
import '../providers/incidences_provider.dart';
import '../widgets/incidence_form.dart';

class EditIncidenceScreen extends ConsumerWidget {
  final IncidenceModel incidence;

  const EditIncidenceScreen({super.key, required this.incidence});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final updateState = ref.watch(incidenceUpdateProvider);

    return Scaffold(
      backgroundColor: AppColors.bgDarkTop,
      appBar: AppBar(
        backgroundColor: AppColors.bgDarkTop,
        title: Text('Editar incidencia', style: AppTheme.headingMd),
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
                'Modificá los datos de la incidencia.',
                style: AppTheme.bodyLg,
              ),
              const SizedBox(height: 24),
              IncidenceForm(
                existingIncidence: incidence,
                isLoading: updateState.isLoading,
                errorMessage: updateState.error?.toString(),
                onSubmit: (data) async {
                  final updated = incidence.copyWith(
                    type: data.type,
                    fechaInicio: data.fechaInicio,
                    fechaFin: data.fechaFin,
                    observaciones: data.observaciones,
                    documentoRelacionado: data.documentoRelacionado,
                    updatedAt: DateTime.now(),
                  );
                  await ref.read(incidenceUpdateProvider.notifier).updateIncidence(updated);
                  if (context.mounted) {
                    ref.read(incidenceUpdateProvider.notifier).reset();
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
