import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/constants/app_colors.dart';
import '../../data/models/medical_document_model.dart';
import '../providers/medical_documents_provider.dart';
import '../widgets/medical_document_form.dart';

class EditMedicalDocumentScreen extends ConsumerWidget {
  final MedicalDocumentModel document;

  const EditMedicalDocumentScreen({super.key, required this.document});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final updateState = ref.watch(medicalDocumentUpdateProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Editar documento médico'),
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
                'Modificá los datos del documento médico.',
                style: TextStyle(color: AppColors.textSecondary, fontSize: 14),
              ),
              const SizedBox(height: 24),
              MedicalDocumentForm(
                existingDocument: document,
                isLoading: updateState.isLoading,
                uploadProgress: updateState.uploadProgress,
                errorMessage: updateState.error?.toString(),
                onSubmit: (data) async {
                  final updated = document.copyWith(
                    tipo: data.tipo,
                    fechaInicio: data.fechaInicio,
                    fechaFin: data.fechaFin,
                    motivo: data.motivo,
                    archivoUrl: data.archivoUrl,
                    updatedAt: DateTime.now(),
                  );
                  final notifier = ref.read(medicalDocumentUpdateProvider.notifier);
                  await notifier.updateDocument(document: updated, file: data.archivoFile);
                  if (context.mounted) {
                    final currentState = ref.read(medicalDocumentUpdateProvider);
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
