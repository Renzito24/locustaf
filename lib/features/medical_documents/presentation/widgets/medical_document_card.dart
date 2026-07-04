import 'package:flutter/material.dart';

import '../../../../core/constants/app_colors.dart';
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
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: Colors.grey.shade200),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
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
                        color: AppColors.textPrimary,
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
              if (document.motivo.isNotEmpty)
                Text(
                  document.motivo,
                  style: const TextStyle(fontSize: 13, color: AppColors.textSecondary),
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
    Color bgColor;
    Color textColor;
    switch (vigencia) {
      case VigenciaEstado.vigente:
        bgColor = AppColors.success.withValues(alpha: 0.1);
        textColor = AppColors.success;
      case VigenciaEstado.proximoAVencer:
        bgColor = AppColors.warning.withValues(alpha: 0.1);
        textColor = AppColors.warning;
      case VigenciaEstado.vencido:
        bgColor = AppColors.error.withValues(alpha: 0.1);
        textColor = AppColors.error;
    }
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        vigencia.label,
        style: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w600,
          color: textColor,
        ),
      ),
    );
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
        Icon(icon, size: 14, color: AppColors.textSecondary),
        const SizedBox(width: 4),
        Text(
          text,
          style: const TextStyle(fontSize: 13, color: AppColors.textSecondary),
        ),
      ],
    );
  }
}
