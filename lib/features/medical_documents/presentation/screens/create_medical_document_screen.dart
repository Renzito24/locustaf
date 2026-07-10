import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/constants/app_colors.dart';
import '../../data/models/medical_document_model.dart';
import '../providers/medical_documents_provider.dart';
import '../widgets/medical_document_form.dart';

class CreateMedicalDocumentScreen extends ConsumerWidget {
  const CreateMedicalDocumentScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final createState = ref.watch(medicalDocumentCreateProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Nuevo documento médico'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.pop(),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 600),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Completá los datos del nuevo documento médico.',
                style: TextStyle(color: AppColors.textSecondary, fontSize: 14),
              ),
              const SizedBox(height: 24),
              MedicalDocumentForm(
                isLoading: createState.isLoading,
                uploadProgress: createState.uploadProgress,
                errorMessage: createState.error?.toString(),
                onSubmit: (data) async {
                  final now = DateTime.now();
                  final doc = MedicalDocumentModel(
                    id: '',
                    userId: data.userId,
                    tipo: data.tipo,
                    fechaInicio: data.fechaInicio,
                    fechaFin: data.fechaFin,
                    motivo: data.motivo,
                    archivoUrl: data.archivoUrl,
                    createdAt: now,
                  );
                  final notifier = ref.read(medicalDocumentCreateProvider.notifier);
                  await notifier.createDocument(document: doc, file: data.archivoFile);
                  if (context.mounted) {
                    final currentState = ref.read(medicalDocumentCreateProvider);
                    if (currentState.hasError) return;
                    notifier.reset();
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
