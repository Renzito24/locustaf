import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/providers/data_providers.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../authentication/presentation/providers/auth_provider.dart';
import '../../../medical_documents/data/models/medical_document_model.dart';
import '../../../medical_documents/presentation/providers/medical_documents_provider.dart';
import '../../../medical_documents/presentation/widgets/medical_document_form.dart';

class EmployeeCreateMedicalDocumentScreen extends ConsumerWidget {
  const EmployeeCreateMedicalDocumentScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final createState = ref.watch(medicalDocumentCreateProvider);
    final authUser = ref.watch(currentUserProvider);
    final userId = authUser?.uid;

    return Scaffold(
      backgroundColor: AppColors.bgDarkTop,
      appBar: AppBar(
        backgroundColor: AppColors.bgDarkTop,
        title: Text('Nuevo certificado médico', style: AppTheme.headingMd),
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
                'Completá los datos de tu certificado médico. Quedará pendiente de aprobación.',
                style: AppTheme.bodyLg,
              ),
              const SizedBox(height: 24),
              MedicalDocumentForm(
                fixedUserId: userId,
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
                    estado: MedicalDocumentEstado.pendiente,
                    companyId: ref.read(currentCompanyIdProvider),
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
