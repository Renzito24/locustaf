import 'package:flutter/material.dart';

import '../../../../core/constants/app_colors.dart';
import '../../data/models/incidence_model.dart';

class IncidenceDetailDialog extends StatelessWidget {
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
  Widget build(BuildContext context) {
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
                    child: const Icon(Icons.warning_amber, color: AppColors.primary, size: 20),
                  ),
                  const SizedBox(width: 12),
                  const Text(
                    'Detalle de incidencia',
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
              _DetailRow(label: 'Tipo', value: incidence.type.label),
              _DetailRow(
                label: 'Período',
                value: '${_formatDate(incidence.fechaInicio)} → ${_formatDate(incidence.fechaFin)}',
              ),
              _DetailRow(label: 'Estado', value: incidence.state.label, valueColor: _stateColor(incidence.state)),
              if (incidence.observaciones.isNotEmpty)
                _DetailRow(label: 'Observaciones', value: incidence.observaciones),
              if (incidence.documentoRelacionado != null && incidence.documentoRelacionado!.isNotEmpty)
                _DetailRow(label: 'Documento', value: incidence.documentoRelacionado!),
            ],
          ),
        ),
      ),
    );
  }

  String _formatDate(DateTime dt) {
    return '${dt.year}-${dt.month.toString().padLeft(2, '0')}-${dt.day.toString().padLeft(2, '0')}';
  }

  Color _stateColor(IncidenceState state) {
    switch (state) {
      case IncidenceState.programada:
        return AppColors.primary;
      case IncidenceState.enCurso:
        return AppColors.success;
      case IncidenceState.finalizada:
        return AppColors.textSecondary;
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
            child: Text(label, style: const TextStyle(color: AppColors.textSecondary, fontSize: 14)),
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
