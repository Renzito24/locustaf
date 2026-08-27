import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/router/app_routes.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../authentication/presentation/providers/auth_provider.dart';
import '../../../incidences/data/models/incidence_model.dart';
import '../../../incidences/presentation/providers/incidences_provider.dart';
import '../../../incidences/presentation/widgets/incidence_card.dart';
import '../../../medical_documents/data/models/medical_document_model.dart';
import '../../../medical_documents/presentation/providers/medical_documents_provider.dart';
import '../../../medical_documents/presentation/widgets/medical_document_card.dart';

class EmployeeJustificativosScreen extends ConsumerWidget {
  const EmployeeJustificativosScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authUser = ref.watch(currentUserProvider);
    final userId = authUser?.uid;

    if (userId == null) {
      return Padding(
        padding: const EdgeInsets.all(24),
        child: AppTheme.emptyState(
          icon: Icons.person_off_outlined,
          title: 'Usuario no autenticado',
          subtitle: 'Iniciá sesión para ver tus justificativos.',
        ),
      );
    }

    final incidencesAsync = ref.watch(incidencesStreamProvider);
    final docsAsync = ref.watch(medicalDocumentsStreamProvider);

    final incidences = (incidencesAsync.value ?? [])
        .where((i) => i.isActive && i.userId == userId)
        .toList()
      ..sort((a, b) => b.fechaInicio.compareTo(a.fechaInicio));

    final docs = (docsAsync.value ?? [])
        .where((d) => d.isActive && d.userId == userId)
        .toList()
      ..sort((a, b) => b.fechaInicio.compareTo(a.fechaInicio));

    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Mis justificativos', style: AppTheme.headingLg),
          const SizedBox(height: 4),
          Text(
            'Gestioná tus incidencias y certificados médicos. El administrador los aprueba o rechaza.',
            style: AppTheme.bodyLg,
          ),
          const SizedBox(height: 24),
          Expanded(
            child: ListView(
              children: [
                _SectionHeader(
                  icon: Icons.warning_amber_outlined,
                  title: 'Incidencias',
                  onAdd: () => context.push(RoutePaths.employeeCreateIncidence),
                ),
                const SizedBox(height: 12),
                if (incidences.isEmpty)
                  AppTheme.emptyState(
                    icon: Icons.warning_amber_outlined,
                    title: 'Sin incidencias',
                    subtitle: 'No tenés incidencias cargadas.',
                  )
                else
                  ...incidences.map(
                    (inc) => Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: IncidenceCard(
                        incidence: inc,
                        employeeName: 'Incidencia',
                        onTap: () => _showIncidenceDetail(context, inc),
                      ),
                    ),
                  ),
                const SizedBox(height: 24),
                _SectionHeader(
                  icon: Icons.medical_services_outlined,
                  title: 'Certificados médicos',
                  onAdd: () => context.push(RoutePaths.employeeCreateMedicalDocument),
                ),
                const SizedBox(height: 12),
                if (docs.isEmpty)
                  AppTheme.emptyState(
                    icon: Icons.description_outlined,
                    title: 'Sin certificados',
                    subtitle: 'No tenés certificados médicos cargados.',
                  )
                else
                  ...docs.map(
                    (doc) => Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: MedicalDocumentCard(
                        document: doc,
                        employeeName: 'Certificado médico',
                        onTap: () => _showDocumentDetail(context, doc),
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _showIncidenceDetail(BuildContext context, IncidenceModel inc) {
    showDialog(
      context: context,
      builder: (ctx) => Dialog(
        backgroundColor: AppColors.cardDark,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppTheme.radiusXl),
          side: BorderSide(color: AppColors.gold.withValues(alpha: 0.3)),
        ),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 500),
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Icon(Icons.warning_amber_outlined, color: AppColors.gold, size: 20),
                    const SizedBox(width: 12),
                    Text('Detalle de incidencia', style: AppTheme.headingMd),
                    const Spacer(),
                    IconButton(
                      onPressed: () => Navigator.of(ctx).pop(),
                      icon: const Icon(Icons.close, color: AppColors.textMuted),
                      visualDensity: VisualDensity.compact,
                    ),
                  ],
                ),
                Divider(height: 24, color: AppColors.gold.withValues(alpha: 0.15)),
                _DetailRow(label: 'Tipo', value: inc.type.label),
                _DetailRow(label: 'Inicio', value: _formatDate(inc.fechaInicio)),
                _DetailRow(label: 'Fin', value: _formatDate(inc.fechaFin)),
                _DetailRow(
                  label: 'Aprobación',
                  value: inc.estado.label,
                  valueColor: _estadoColor(inc.estado),
                ),
                if (inc.observaciones.isNotEmpty)
                  _DetailRow(label: 'Observaciones', value: inc.observaciones),
                if (inc.observacionRechazo != null && inc.observacionRechazo!.isNotEmpty)
                  _DetailRow(
                    label: 'Motivo de rechazo',
                    value: inc.observacionRechazo!,
                    valueColor: AppColors.error,
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _showDocumentDetail(BuildContext context, MedicalDocumentModel doc) {
    showDialog(
      context: context,
      builder: (ctx) => Dialog(
        backgroundColor: AppColors.cardDark,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppTheme.radiusXl),
          side: BorderSide(color: AppColors.gold.withValues(alpha: 0.3)),
        ),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 500),
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Icon(Icons.description, color: AppColors.gold, size: 20),
                    const SizedBox(width: 12),
                    Text('Detalle del certificado', style: AppTheme.headingMd),
                    const Spacer(),
                    IconButton(
                      onPressed: () => Navigator.of(ctx).pop(),
                      icon: const Icon(Icons.close, color: AppColors.textMuted),
                      visualDensity: VisualDensity.compact,
                    ),
                  ],
                ),
                Divider(height: 24, color: AppColors.gold.withValues(alpha: 0.15)),
                _DetailRow(label: 'Tipo', value: doc.tipo.label),
                _DetailRow(label: 'Emisión', value: _formatDate(doc.fechaInicio)),
                _DetailRow(label: 'Vencimiento', value: _formatDate(doc.fechaFin)),
                _DetailRow(
                  label: 'Aprobación',
                  value: doc.estado.label,
                  valueColor: _docEstadoColor(doc.estado),
                ),
                if (doc.motivo.isNotEmpty)
                  _DetailRow(label: 'Observaciones', value: doc.motivo),
                if (doc.observacionRechazo != null && doc.observacionRechazo!.isNotEmpty)
                  _DetailRow(
                    label: 'Motivo de rechazo',
                    value: doc.observacionRechazo!,
                    valueColor: AppColors.error,
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  String _formatDate(DateTime dt) {
    return '${dt.year}-${dt.month.toString().padLeft(2, '0')}-${dt.day.toString().padLeft(2, '0')}';
  }

  Color _estadoColor(IncidenceEstado e) {
    switch (e) {
      case IncidenceEstado.pendiente:
        return AppColors.warning;
      case IncidenceEstado.aprobado:
        return AppColors.success;
      case IncidenceEstado.rechazado:
        return AppColors.error;
    }
  }

  Color _docEstadoColor(MedicalDocumentEstado e) {
    switch (e) {
      case MedicalDocumentEstado.pendiente:
        return AppColors.warning;
      case MedicalDocumentEstado.aprobado:
        return AppColors.success;
      case MedicalDocumentEstado.rechazado:
        return AppColors.error;
    }
  }
}

class _SectionHeader extends StatelessWidget {
  final IconData icon;
  final String title;
  final VoidCallback onAdd;

  const _SectionHeader({
    required this.icon,
    required this.title,
    required this.onAdd,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 20, color: AppColors.gold),
        const SizedBox(width: 8),
        Text(title, style: AppTheme.headingMd),
        const Spacer(),
        FilledButton.icon(
          onPressed: onAdd,
          icon: const Icon(Icons.add, size: 18),
          label: const Text('Nuevo'),
          style: FilledButton.styleFrom(
            backgroundColor: AppColors.gold,
            foregroundColor: Colors.white,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppTheme.radiusSm)),
          ),
        ),
      ],
    );
  }
}

class _DetailRow extends StatelessWidget {
  final String label;
  final String value;
  final Color? valueColor;

  const _DetailRow({
    required this.label,
    required this.value,
    this.valueColor,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 130,
            child: Text(
              label,
              style: const TextStyle(color: AppColors.textMuted, fontSize: 14),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: TextStyle(
                color: valueColor ?? AppColors.textWhite,
                fontSize: 14,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
