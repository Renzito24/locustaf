import 'package:flutter/material.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/theme/app_theme.dart';
import '../../data/models/medical_document_model.dart';

class MedicalDocumentCard extends StatelessWidget {
  final MedicalDocumentModel document;
  final String employeeName;
  final VoidCallback? onTap;
  final VoidCallback? onDelete;

  const MedicalDocumentCard({
    super.key,
    required this.document,
    required this.employeeName,
    this.onTap,
    this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: AppTheme.cardDecoration(),
      child: InkWell(
        borderRadius: BorderRadius.circular(AppTheme.radiusXl),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      employeeName,
                      style: const TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 15,
                        color: AppColors.textWhite,
                      ),
                    ),
                  ),
                  _VigenciaBadge(vigencia: document.vigencia),
                ],
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  _InfoChip(icon: Icons.description, text: document.tipo.label),
                  const SizedBox(width: 12),
                  _InfoChip(icon: Icons.event, text: _formatDate(document.fechaInicio)),
                  const SizedBox(width: 12),
                  _InfoChip(icon: Icons.event_busy, text: _formatDate(document.fechaFin)),
                ],
              ),
              const SizedBox(height: 6),
              if (document.archivoUrl != null)
                Padding(
                  padding: const EdgeInsets.only(top: 6),
                  child: Row(
                    children: [
                      const Icon(Icons.attach_file, size: 14, color: AppColors.gold),
                      const SizedBox(width: 4),
                      Expanded(
                        child: Text(
                          document.archivoNombre ?? 'Archivo adjunto',
                          style: const TextStyle(fontSize: 12, color: AppColors.gold),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ),
              if (document.motivo.isNotEmpty)
                Text(
                  document.motivo,
                  style: const TextStyle(fontSize: 13, color: AppColors.textMuted),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              if (onDelete != null)
                Align(
                  alignment: Alignment.centerRight,
                  child: IconButton(
                    icon: const Icon(Icons.delete_outline, size: 18, color: AppColors.error),
                    onPressed: onDelete,
                    tooltip: 'Eliminar',
                    visualDensity: VisualDensity.compact,
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  String _formatDate(DateTime dt) {
    return '${dt.year}-${dt.month.toString().padLeft(2, '0')}-${dt.day.toString().padLeft(2, '0')}';
  }
}

class _VigenciaBadge extends StatelessWidget {
  final VigenciaEstado vigencia;

  const _VigenciaBadge({required this.vigencia});

  @override
  Widget build(BuildContext context) {
    switch (vigencia) {
      case VigenciaEstado.vigente:
        return AppTheme.badge(label: vigencia.label, bgColor: AppColors.success.withValues(alpha: 0.15), textColor: AppColors.success);
      case VigenciaEstado.proximoAVencer:
        return AppTheme.badge(label: vigencia.label, bgColor: AppColors.warning.withValues(alpha: 0.15), textColor: AppColors.warning);
      case VigenciaEstado.vencido:
        return AppTheme.badge(label: vigencia.label, bgColor: AppColors.error.withValues(alpha: 0.15), textColor: AppColors.error);
    }
  }
}

class _InfoChip extends StatelessWidget {
  final IconData icon;
  final String text;

  const _InfoChip({required this.icon, required this.text});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 14, color: AppColors.textMuted),
        const SizedBox(width: 4),
        Text(
          text,
          style: const TextStyle(fontSize: 13, color: AppColors.textMuted),
        ),
      ],
    );
  }
}
