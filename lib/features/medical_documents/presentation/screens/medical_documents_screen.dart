import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/providers/async_action_state.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../authentication/presentation/providers/auth_provider.dart';
import '../../../employees/presentation/providers/users_provider.dart';
import '../providers/medical_documents_provider.dart';
import 'medical_documents_components.dart';

class MedicalDocumentsScreen extends ConsumerWidget {
  const MedicalDocumentsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final docs = ref.watch(filteredMedicalDocumentsProvider);
    final total = ref.watch(totalMedicalDocumentsProvider);
    final vigentes = ref.watch(vigentesCountProvider);
    final proximos = ref.watch(proximosAVencerCountProvider);
    final vencidos = ref.watch(vencidosCountProvider);
    final usersAsync = ref.watch(usersStreamProvider);
    final isAdmin = ref.watch(isAdminProvider);

    ref.listen<AsyncActionState>(medicalDocumentDeleteProvider, (prev, next) {
      if (prev?.status != AsyncActionStatus.loading) return;
      if (next.status == AsyncActionStatus.success) {
        ref.read(medicalDocumentDeleteProvider.notifier).reset();
        ScaffoldMessenger.of(context).showSnackBar(
          AppTheme.successSnackBar('Documento eliminado correctamente'),
        );
      } else if (next.status == AsyncActionStatus.failure) {
        ScaffoldMessenger.of(context).showSnackBar(
          AppTheme.errorSnackBar('Error al eliminar: ${next.error}'),
        );
      }
    });

    ref.listen<AsyncActionState>(medicalDocumentApprovalProvider, (prev, next) {
      if (prev?.status != AsyncActionStatus.loading) return;
      if (next.status == AsyncActionStatus.success) {
        ref.read(medicalDocumentApprovalProvider.notifier).reset();
        ScaffoldMessenger.of(context).showSnackBar(
          AppTheme.successSnackBar('Estado del documento actualizado'),
        );
      } else if (next.status == AsyncActionStatus.failure) {
        ScaffoldMessenger.of(context).showSnackBar(
          AppTheme.errorSnackBar('Error al actualizar el estado: ${next.error}'),
        );
      }
    });

    return CustomScrollView(
      slivers: [
        SliverPadding(
          padding: const EdgeInsets.fromLTRB(24, 24, 24, 0),
          sliver: SliverToBoxAdapter(
            child: MedicalDocumentsHeader(
              total: total,
              vigentes: vigentes,
              proximos: proximos,
              vencidos: vencidos,
              isAdmin: isAdmin,
            ),
          ),
        ),
        SliverPadding(
          padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
          sliver: MedicalDocumentsSliverContent(
            docs: docs,
            usersAsync: usersAsync,
            isAdmin: isAdmin,
          ),
        ),
      ],
    );
  }
}
