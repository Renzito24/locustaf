import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/providers/async_action_state.dart';
import '../../../../core/router/app_routes.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/models/user_model.dart';
import '../../../../core/utils/string_utils.dart';
import '../../../../core/widgets/metric_cards.dart';
import '../../../authentication/presentation/providers/auth_provider.dart';
import '../../../employees/presentation/providers/users_provider.dart';
import '../../data/models/medical_document_model.dart';
import '../providers/medical_documents_provider.dart';
import '../widgets/medical_document_card.dart';
import '../widgets/medical_document_detail_dialog.dart';
import '../widgets/medical_document_filter_bar.dart';

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

    // Todo el contenido (cabecera + métricas + filtros + listado) vive dentro
    // de un único CustomScrollView: en teléfonos chicos la página scrollea
    // como una sola unidad y vacían de los `BOTTOM OVERFLOWED` que generaba la
    // columna no scrolleable (Fase B — Corrección).
    return CustomScrollView(
      slivers: [
        SliverPadding(
          padding: const EdgeInsets.fromLTRB(24, 24, 24, 0),
          sliver: SliverList.list(
            children: [
              Text('Documentación Médica', style: AppTheme.headingLg),
              const SizedBox(height: 4),
              Text(
                'Administra los certificados y documentación médica de los empleados.',
                style: AppTheme.bodyLg,
              ),
              const SizedBox(height: 24),
              MetricCardsGrid(
                cards: [
                  MetricCardData(
                    icon: Icons.description,
                    label: 'Total documentos',
                    value: total.toString(),
                    color: AppColors.gold,
                  ),
                  MetricCardData(
                    icon: Icons.check_circle,
                    label: 'Vigentes',
                    value: vigentes.toString(),
                    color: AppColors.success,
                  ),
                  MetricCardData(
                    icon: Icons.warning,
                    label: 'Próximo a vencer',
                    value: proximos.toString(),
                    color: AppColors.warning,
                  ),
                  MetricCardData(
                    icon: Icons.cancel,
                    label: 'Vencidos',
                    value: vencidos.toString(),
                    color: AppColors.error,
                  ),
                ],
              ),
              const SizedBox(height: 24),
              const MedicalDocumentFilterBar(),
              const SizedBox(height: 16),
              if (isAdmin)
                Align(
                  alignment: Alignment.centerRight,
                  child: FilledButton.icon(
                    onPressed: () => context.push(RoutePaths.createMedicalDocument),
                    icon: const Icon(Icons.add, size: 18),
                    label: const Text('Nuevo documento'),
                    style: FilledButton.styleFrom(
                      backgroundColor: AppColors.gold,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppTheme.radiusSm)),
                    ),
                  ),
                ),
              const SizedBox(height: 16),
            ],
          ),
        ),
        SliverPadding(
          padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
          sliver: _buildContentSliver(context, ref, docs, usersAsync, isAdmin),
        ),
      ],
    );
  }

  Widget _buildContentSliver(
    BuildContext context,
    WidgetRef ref,
    List<MedicalDocumentModel> docs,
    AsyncValue<List<UserModel>> usersAsync,
    bool isAdmin,
  ) {
    return usersAsync.when(
      data: (users) {
        final userMap = {for (final u in users) u.id: u};

        if (docs.isEmpty) {
          return SliverFillRemaining(
            hasScrollBody: false,
            child: AppTheme.emptyState(
              icon: Icons.description_outlined,
              title: 'Sin documentos médicos',
              subtitle: 'No hay documentos para los filtros seleccionados.',
            ),
          );
        }

        return SliverLayoutBuilder(
          builder: (context, constraints) {
            if (constraints.crossAxisExtent < 800) {
              return SliverList.separated(
                itemCount: docs.length,
                separatorBuilder: (_, _) => const SizedBox(height: 8),
                itemBuilder: (context, index) {
                  final doc = docs[index];
                  final user = userMap[doc.userId];
                  return MedicalDocumentCard(
                    document: doc,
                    employeeName: user?.nombreCompleto ?? 'Usuario ${StringUtils.safePrefix(doc.userId, 6)}',
                    onTap: () => MedicalDocumentDetailDialog.show(
                      context,
                      document: doc,
                      employeeName: user?.nombreCompleto ?? 'Desconocido',
                      employeeEmail: user?.email ?? '',
                    ),
                    onDelete: isAdmin
                        ? () => _confirmDelete(context, ref, doc)
                        : null,
                  );
                },
              );
            }

            return SliverToBoxAdapter(
              child: SingleChildScrollView(
                scrollDirection: Axis.vertical,
                child: SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: DataTable(
                  columnSpacing: 20,
                  headingRowColor: WidgetStateProperty.all(AppColors.gold.withValues(alpha: 0.1)),
                  columns: [
                    const DataColumn(label: Text('Empleado', style: TextStyle(fontWeight: FontWeight.bold, color: AppColors.gold))),
                    const DataColumn(label: Text('Tipo', style: TextStyle(fontWeight: FontWeight.bold, color: AppColors.gold))),
                    const DataColumn(label: Text('Emisión', style: TextStyle(fontWeight: FontWeight.bold, color: AppColors.gold))),
                    const DataColumn(label: Text('Vencimiento', style: TextStyle(fontWeight: FontWeight.bold, color: AppColors.gold))),
                    const DataColumn(label: Text('Vigencia', style: TextStyle(fontWeight: FontWeight.bold, color: AppColors.gold))),
                    const DataColumn(label: Text('Aprobación', style: TextStyle(fontWeight: FontWeight.bold, color: AppColors.gold))),
                    if (isAdmin) const DataColumn(label: Text('Acciones', style: TextStyle(fontWeight: FontWeight.bold, color: AppColors.gold))),
                  ],
                  rows: docs.map((doc) {
                    final user = userMap[doc.userId];
                    final name = user?.nombreCompleto ?? 'Usuario ${doc.userId.substring(0, 6)}';
                    return DataRow(
                      onSelectChanged: (_) => MedicalDocumentDetailDialog.show(
                        context,
                        document: doc,
                        employeeName: name,
                        employeeEmail: user?.email ?? '',
                      ),
                      cells: [
                        DataCell(Text(name, style: const TextStyle(color: AppColors.textWhite))),
                        DataCell(Text(doc.tipo.label, style: const TextStyle(color: AppColors.textMuted))),
                        DataCell(Text(_formatDate(doc.fechaInicio), style: const TextStyle(color: AppColors.textMuted))),
                        DataCell(Text(_formatDate(doc.fechaFin), style: const TextStyle(color: AppColors.textMuted))),
                        DataCell(_buildEstadoChip(doc.vigencia)),
                        DataCell(_buildAprobacionChip(doc.estado)),
                        if (isAdmin)
                          DataCell(Row(
                            children: [
                              IconButton(
                                icon: const Icon(Icons.edit, size: 18, color: AppColors.gold),
                                onPressed: () => context.push(
                                  RoutePaths.editMedicalDocument,
                                  extra: doc,
                                ),
                                tooltip: 'Editar',
                                visualDensity: VisualDensity.compact,
                              ),
                              IconButton(
                                icon: const Icon(Icons.delete_outline, size: 18, color: AppColors.error),
                                onPressed: () => _confirmDelete(context, ref, doc),
                                tooltip: 'Eliminar',
                                visualDensity: VisualDensity.compact,
                              ),
                            ],
                          )),
                      ],
                    );
                  }).toList(),
                  ),
                ),
              ),
            );
          },
        );
      },
      loading: () => SliverFillRemaining(hasScrollBody: false, child: AppTheme.loadingState()),
      error: (_, _) => SliverFillRemaining(
        hasScrollBody: false,
        child: AppTheme.errorState('No se pudieron obtener los datos de los empleados.'),
      ),
    );
  }

  String _formatDate(DateTime dt) {
    return '${dt.year}-${dt.month.toString().padLeft(2, '0')}-${dt.day.toString().padLeft(2, '0')}';
  }

  Widget _buildEstadoChip(VigenciaEstado vigencia) {
    switch (vigencia) {
      case VigenciaEstado.vigente:
        return AppTheme.badge(label: vigencia.label, bgColor: AppColors.success.withValues(alpha: 0.15), textColor: AppColors.success);
      case VigenciaEstado.proximoAVencer:
        return AppTheme.badge(label: vigencia.label, bgColor: AppColors.warning.withValues(alpha: 0.15), textColor: AppColors.warning);
      case VigenciaEstado.vencido:
        return AppTheme.badge(label: vigencia.label, bgColor: AppColors.error.withValues(alpha: 0.15), textColor: AppColors.error);
    }
  }

  Widget _buildAprobacionChip(MedicalDocumentEstado estado) {
    switch (estado) {
      case MedicalDocumentEstado.pendiente:
        return AppTheme.badge(label: estado.label, bgColor: AppColors.warning.withValues(alpha: 0.15), textColor: AppColors.warning);
      case MedicalDocumentEstado.aprobado:
        return AppTheme.badge(label: estado.label, bgColor: AppColors.success.withValues(alpha: 0.15), textColor: AppColors.success);
      case MedicalDocumentEstado.rechazado:
        return AppTheme.badge(label: estado.label, bgColor: AppColors.error.withValues(alpha: 0.15), textColor: AppColors.error);
    }
  }

  void _confirmDelete(BuildContext context, WidgetRef ref, MedicalDocumentModel doc) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.cardDark,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppTheme.radiusLg),
          side: BorderSide(color: AppColors.gold.withValues(alpha: 0.3)),
        ),
        title: Text('Eliminar documento', style: AppTheme.headingMd),
        content: Text(
          '¿Eliminar el documento de tipo "${doc.tipo.label}"?',
          style: AppTheme.bodyLg,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Cancelar', style: TextStyle(color: AppColors.textMuted)),
          ),
          FilledButton(
            onPressed: () {
              Navigator.of(ctx).pop();
              ref.read(medicalDocumentDeleteProvider.notifier).softDelete(
                doc.id,
                archivoUrl: doc.archivoUrl,
              );
            },
            style: FilledButton.styleFrom(
              backgroundColor: AppColors.error,
              foregroundColor: Colors.white,
            ),
            child: const Text('Eliminar'),
          ),
        ],
      ),
    );
  }
}
