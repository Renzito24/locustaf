import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../authentication/presentation/providers/auth_provider.dart';
import '../../data/models/incidence_model.dart';
import '../providers/incidences_provider.dart';

class IncidenceDetailDialog extends ConsumerWidget {
  final IncidenceModel incidence;
  final String employeeName;
  final String employeeEmail;

  const IncidenceDetailDialog({
    super.key,
    required this.incidence,
    required this.employeeName,
    required this.employeeEmail,
  });

  static Future<void> show(
    BuildContext context, {
    required IncidenceModel incidence,
    required String employeeName,
    required String employeeEmail,
  }) {
    return showDialog(
      context: context,
      builder: (_) => IncidenceDetailDialog(
        incidence: incidence,
        employeeName: employeeName,
        employeeEmail: employeeEmail,
      ),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isAdmin = ref.watch(isAdminProvider);
    final isApproving = ref.watch(incidenceApprovalProvider).isLoading;

    return Dialog(
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
                  Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: AppColors.gold.withValues(alpha: 0.15),
                    ),
                    child: const Icon(Icons.warning_amber, color: AppColors.gold, size: 20),
                  ),
                  const SizedBox(width: 12),
                  Text('Detalle de incidencia', style: AppTheme.headingMd),
                  const Spacer(),
                  IconButton(
                    onPressed: () => Navigator.of(context).pop(),
                    icon: const Icon(Icons.close, color: AppColors.textMuted),
                    visualDensity: VisualDensity.compact,
                  ),
                ],
              ),
              Divider(height: 24, color: AppColors.gold.withValues(alpha: 0.15)),
              _DetailRow(label: 'Empleado', value: employeeName),
              _DetailRow(label: 'Email', value: employeeEmail),
              _DetailRow(label: 'Tipo', value: incidence.type.label),
              _DetailRow(
                label: 'Período',
                value: '${_formatDate(incidence.fechaInicio)} → ${_formatDate(incidence.fechaFin)}',
              ),
              _DetailRow(label: 'Estado', value: incidence.state.label, valueColor: _stateColor(incidence.state)),
              _DetailRow(
                label: 'Aprobación',
                value: incidence.estado.label,
                valueColor: _estadoColor(incidence.estado),
              ),
              if (incidence.observaciones.isNotEmpty)
                _DetailRow(label: 'Observaciones', value: incidence.observaciones),
              if (incidence.documentoRelacionado != null && incidence.documentoRelacionado!.isNotEmpty)
                _DocumentRow(url: incidence.documentoRelacionado!),
              if (incidence.observacionRechazo != null && incidence.observacionRechazo!.isNotEmpty)
                _DetailRow(
                  label: 'Motivo de rechazo',
                  value: incidence.observacionRechazo!,
                  valueColor: AppColors.error,
                ),
              if (isAdmin && incidence.estado == IncidenceEstado.pendiente) ...[
                const SizedBox(height: 16),
                Divider(height: 24, color: AppColors.gold.withValues(alpha: 0.15)),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: isApproving
                            ? null
                            : () => _confirmReject(context, ref),
                        icon: const Icon(Icons.close, size: 18),
                        label: const Text('Rechazar'),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: AppColors.error,
                          side: const BorderSide(color: AppColors.error),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: FilledButton.icon(
                        onPressed: isApproving
                            ? null
                            : () {
                                ref.read(incidenceApprovalProvider.notifier)
                                    .approve(incidence.id);
                              },
                        icon: const Icon(Icons.check, size: 18),
                        label: const Text('Aprobar'),
                        style: FilledButton.styleFrom(
                          backgroundColor: AppColors.success,
                          foregroundColor: Colors.white,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  void _confirmReject(BuildContext context, WidgetRef ref) {
    final controller = TextEditingController();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.cardDark,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppTheme.radiusLg),
          side: BorderSide(color: AppColors.gold.withValues(alpha: 0.3)),
        ),
        title: Text('Rechazar incidencia', style: AppTheme.headingMd),
        content: TextField(
          controller: controller,
          maxLines: 3,
          style: const TextStyle(color: AppColors.textWhite),
          decoration: AppTheme.inputDecoration(
            label: 'Motivo del rechazo *',
            icon: Icons.comment_outlined,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Cancelar', style: TextStyle(color: AppColors.textMuted)),
          ),
          FilledButton(
            onPressed: () {
              final motivo = controller.text.trim();
              if (motivo.isEmpty) return;
              Navigator.of(ctx).pop();
              ref.read(incidenceApprovalProvider.notifier)
                  .reject(incidence.id, observacion: motivo);
            },
            style: FilledButton.styleFrom(
              backgroundColor: AppColors.error,
              foregroundColor: Colors.white,
            ),
            child: const Text('Rechazar'),
          ),
        ],
      ),
    );
  }

  String _formatDate(DateTime dt) {
    return '${dt.year}-${dt.month.toString().padLeft(2, '0')}-${dt.day.toString().padLeft(2, '0')}';
  }

  Color _stateColor(IncidenceState state) {
    switch (state) {
      case IncidenceState.programada:
        return AppColors.gold;
      case IncidenceState.enCurso:
        return AppColors.success;
      case IncidenceState.finalizada:
        return AppColors.textMuted;
    }
  }

  Color _estadoColor(IncidenceEstado estado) {
    switch (estado) {
      case IncidenceEstado.pendiente:
        return AppColors.warning;
      case IncidenceEstado.aprobado:
        return AppColors.success;
      case IncidenceEstado.rechazado:
        return AppColors.error;
    }
  }
}

class _DetailRow extends StatelessWidget {
  final String label;
  final String value;
  final Color? valueColor;

  const _DetailRow({required this.label, required this.value, this.valueColor});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 130,
            child: Text(label, style: const TextStyle(color: AppColors.textMuted, fontSize: 14)),
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

class _DocumentRow extends StatelessWidget {
  final String url;

  const _DocumentRow({required this.url});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(
            width: 130,
            child: Text('Documento', style: TextStyle(color: AppColors.textMuted, fontSize: 14)),
          ),
          Expanded(
            child: Align(
              alignment: Alignment.centerLeft,
              child: TextButton.icon(
                onPressed: () {
                  showDialog(
                    context: context,
                    builder: (_) => _ImageViewerDialog(url: url),
                  );
                },
                icon: const Icon(Icons.image, size: 18, color: AppColors.gold),
                label: const Text(
                  'Ver imagen',
                  style: TextStyle(color: AppColors.gold, fontWeight: FontWeight.w600),
                ),
                style: TextButton.styleFrom(
                  padding: EdgeInsets.zero,
                  minimumSize: const Size(0, 0),
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ImageViewerDialog extends StatelessWidget {
  final String url;

  const _ImageViewerDialog({required this.url});

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: EdgeInsets.zero,
      child: Stack(
        fit: StackFit.expand,
        children: [
          InteractiveViewer(
            child: Image.network(
              url,
              fit: BoxFit.contain,
              loadingBuilder: (context, child, loadingProgress) {
                if (loadingProgress == null) return child;
                return const Center(
                  child: CircularProgressIndicator(color: AppColors.gold),
                );
              },
              errorBuilder: (context, error, stackTrace) {
                return const Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.broken_image, size: 64, color: AppColors.textMuted),
                      SizedBox(height: 16),
                      Text('No se pudo cargar la imagen', style: TextStyle(color: Colors.white)),
                    ],
                  ),
                );
              },
            ),
          ),
          Positioned(
            top: 16,
            left: 16,
            child: IconButton(
              icon: const Icon(Icons.arrow_back, color: Colors.white, size: 30),
              onPressed: () => Navigator.of(context).pop(),
            ),
          ),
        ],
      ),
    );
  }
}
