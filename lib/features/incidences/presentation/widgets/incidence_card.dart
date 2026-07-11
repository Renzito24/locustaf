import 'package:flutter/material.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/theme/app_theme.dart';
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
                  style: const TextStyle(fontSize: 13, color: AppColors.textMuted),
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
    switch (state) {
      case IncidenceState.programada:
        return AppTheme.badge(label: state.label, bgColor: AppColors.gold.withValues(alpha: 0.15), textColor: AppColors.gold);
      case IncidenceState.enCurso:
        return AppTheme.badge(label: state.label, bgColor: AppColors.success.withValues(alpha: 0.15), textColor: AppColors.success);
      case IncidenceState.finalizada:
        return AppTheme.badge(label: state.label, bgColor: AppColors.textMuted.withValues(alpha: 0.15), textColor: AppColors.textMuted);
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
        Text(text, style: const TextStyle(fontSize: 13, color: AppColors.textMuted)),
      ],
    );
  }
}
