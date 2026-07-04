import 'package:flutter/material.dart';

import '../../../../core/constants/app_colors.dart';
import '../../data/models/incidence_model.dart';

class IncidenceCard extends StatelessWidget {
  final IncidenceModel incidence;
  final String employeeName;
  final VoidCallback? onTap;
  final VoidCallback? onDelete;

  const IncidenceCard({
    super.key,
    required this.incidence,
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
                  _StateBadge(state: incidence.state),
                ],
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  _InfoChip(icon: Icons.category, text: incidence.type.label),
                  const SizedBox(width: 12),
                  _InfoChip(icon: Icons.event, text: _formatDate(incidence.fechaInicio)),
                  const SizedBox(width: 12),
                  _InfoChip(icon: Icons.event_busy, text: _formatDate(incidence.fechaFin)),
                ],
              ),
              if (incidence.observaciones.isNotEmpty) ...[
                const SizedBox(height: 6),
                Text(
                  incidence.observaciones,
                  style: const TextStyle(fontSize: 13, color: AppColors.textSecondary),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
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

class _StateBadge extends StatelessWidget {
  final IncidenceState state;

  const _StateBadge({required this.state});

  @override
  Widget build(BuildContext context) {
    Color bgColor;
    Color textColor;
    switch (state) {
      case IncidenceState.programada:
        bgColor = AppColors.primary.withValues(alpha: 0.1);
        textColor = AppColors.primary;
      case IncidenceState.enCurso:
        bgColor = AppColors.success.withValues(alpha: 0.1);
        textColor = AppColors.success;
      case IncidenceState.finalizada:
        bgColor = AppColors.textSecondary.withValues(alpha: 0.1);
        textColor = AppColors.textSecondary;
    }
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(color: bgColor, borderRadius: BorderRadius.circular(12)),
      child: Text(
        state.label,
        style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: textColor),
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
        Text(text, style: const TextStyle(fontSize: 13, color: AppColors.textSecondary)),
      ],
    );
  }
}
