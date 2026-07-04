import 'package:flutter/material.dart';

import '../../../../core/constants/app_colors.dart';
import '../../data/models/medical_document_model.dart';

class MedicalDocumentDetailDialog extends StatelessWidget {
  final MedicalDocumentModel document;
  final String employeeName;
  final String employeeEmail;

  const MedicalDocumentDetailDialog({
    super.key,
    required this.document,
    required this.employeeName,
    required this.employeeEmail,
  });

  static Future<void> show(
    BuildContext context, {
    required MedicalDocumentModel document,
    required String employeeName,
    required String employeeEmail,
  }) {
    return showDialog(
      context: context,
      builder: (_) => MedicalDocumentDetailDialog(
        document: document,
        employeeName: employeeName,
        employeeEmail: employeeEmail,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final issue = _formatDate(document.fechaInicio);
    final expiry = _formatDate(document.fechaFin);

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
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
                      color: AppColors.primary.withValues(alpha: 0.1),
                    ),
                    child: const Icon(Icons.description, color: AppColors.primary, size: 20),
                  ),
                  const SizedBox(width: 12),
                  const Text(
                    'Detalle del documento',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  const Spacer(),
                  IconButton(
                    onPressed: () => Navigator.of(context).pop(),
                    icon: const Icon(Icons.close),
                    visualDensity: VisualDensity.compact,
                  ),
                ],
              ),
              const Divider(height: 24),
              _DetailRow(label: 'Empleado', value: employeeName),
              _DetailRow(label: 'Email', value: employeeEmail),
              _DetailRow(label: 'Tipo', value: document.tipo.label),
              _DetailRow(label: 'Emisión', value: issue),
              _DetailRow(label: 'Vencimiento', value: expiry),
              _DetailRow(
                label: 'Estado',
                value: document.vigencia.label,
                valueColor: _vigenciaColor(document.vigencia),
              ),
              if (document.motivo.isNotEmpty)
                _DetailRow(label: 'Observaciones', value: document.motivo),
              if (document.archivoUrl != null && document.archivoUrl!.isNotEmpty)
                _DetailRow(label: 'Documento', value: document.archivoUrl!),
            ],
          ),
        ),
      ),
    );
  }

  String _formatDate(DateTime dt) {
    return '${dt.year}-${dt.month.toString().padLeft(2, '0')}-${dt.day.toString().padLeft(2, '0')}';
  }

  Color _vigenciaColor(VigenciaEstado v) {
    switch (v) {
      case VigenciaEstado.vigente:
        return AppColors.success;
      case VigenciaEstado.proximoAVencer:
        return AppColors.warning;
      case VigenciaEstado.vencido:
        return AppColors.error;
    }
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
              style: const TextStyle(
                color: AppColors.textSecondary,
                fontSize: 14,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: TextStyle(
                color: valueColor ?? AppColors.textPrimary,
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
