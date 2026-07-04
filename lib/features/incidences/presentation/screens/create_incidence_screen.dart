import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/constants/app_colors.dart';
import '../../data/models/incidence_model.dart';
import '../providers/incidences_provider.dart';
import '../widgets/incidence_form.dart';

class CreateIncidenceScreen extends ConsumerWidget {
  const CreateIncidenceScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final createState = ref.watch(incidenceCreateProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Nueva incidencia'),
        leading: IconButton(icon: const Icon(Icons.arrow_back), onPressed: () => context.pop()),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 600),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Completá los datos de la nueva incidencia.',
                  style: TextStyle(color: AppColors.textSecondary, fontSize: 14)),
              const SizedBox(height: 24),
              IncidenceForm(
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
