import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/widgets/widgets.dart';
import '../../data/models/workplace_model.dart';
import '../providers/workplace_notifier.dart';

class WorkplaceFilterChip extends StatelessWidget {
  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  const WorkplaceFilterChip({
    super.key,
    required this.label,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return ChoiceChip(
      label: Text(label),
      selected: isSelected,
      onSelected: (_) => onTap(),
      showCheckmark: false,
      selectedColor: AppColors.gold,
      backgroundColor: AppColors.cardDark,
      labelStyle: TextStyle(
        color: isSelected ? const Color(0xFF0B0B0F) : AppColors.textMuted,
        fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
        fontSize: 13,
      ),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
      ),
      side: BorderSide(
        color: isSelected
            ? AppColors.gold
            : AppColors.gold.withValues(alpha: 0.2),
        width: 1,
      ),
    );
  }
}

class WorkplaceCard extends ConsumerStatefulWidget {
  final WorkplaceModel workplace;
  final bool isAdmin;

  const WorkplaceCard({
    super.key,
    required this.workplace,
    required this.isAdmin,
  });

  @override
  ConsumerState<WorkplaceCard> createState() => _WorkplaceCardState();
}

class _WorkplaceCardState extends ConsumerState<WorkplaceCard> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    final workplace = widget.workplace;

    return MouseRegion(
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      child: AppCard(
        isHovered: _isHovered,
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: workplace.isActive
                    ? AppColors.gold.withValues(alpha: 0.12)
                    : AppColors.textMuted.withValues(alpha: 0.08),
              ),
              child: Icon(
                Icons.business,
                color: workplace.isActive ? AppColors.gold : AppColors.textMuted,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    workplace.nombre,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: AppColors.textWhite,
                    ),
                  ),
                  if (workplace.description != null &&
                      workplace.description!.isNotEmpty) ...[
                    const SizedBox(height: 4),
                    Text(
                      workplace.description!,
                      style: AppTheme.bodyMd,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                  if (workplace.direccion != null &&
                      workplace.direccion!.isNotEmpty) ...[
                    const SizedBox(height: 2),
                    Row(
                      children: [
                        const Icon(Icons.location_on, size: 12, color: AppColors.gold),
                        const SizedBox(width: 4),
                        Flexible(
                          child: Text(
                            workplace.direccion!,
                            style: const TextStyle(
                              color: AppColors.textMuted,
                              fontSize: 12,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(width: 8),
            AppTheme.badge(
              label: workplace.isActive ? 'Activo' : 'Inactivo',
              bgColor: workplace.isActive
                  ? AppColors.badgeActiveBg
                  : AppColors.badgeInactiveBg,
              textColor: workplace.isActive
                  ? AppColors.badgeActiveText
                  : AppColors.badgeInactiveText,
            ),
            if (widget.isAdmin) ...[
              const SizedBox(width: 8),
              PopupMenuButton<String>(
                icon: const Icon(Icons.more_vert, color: AppColors.textMuted),
                color: AppColors.cardDark,
                onSelected: (value) {
                  switch (value) {
                    case 'edit':
                      context.push('/workplaces/edit', extra: workplace);
                      break;
                    case 'toggle':
                      if (workplace.isActive) {
                        ref.read(workplaceDeleteProvider.notifier).softDeleteWorkplace(workplace.id);
                      } else {
                        WorkplaceDialogs.confirmReactivate(context, ref, workplace.id);
                      }
                      break;
                  }
                },
                itemBuilder: (context) => [
                  PopupMenuItem(
                    value: 'edit',
                    child: const Row(
                      children: [
                        Icon(Icons.edit_outlined, size: 18, color: AppColors.textWhite),
                        SizedBox(width: 8),
                        Text('Editar', style: TextStyle(color: AppColors.textWhite)),
                      ],
                    ),
                  ),
                  const PopupMenuDivider(color: AppColors.gold),
                  PopupMenuItem(
                    value: 'toggle',
                    child: Row(
                      children: [
                        Icon(
                          workplace.isActive ? Icons.block : Icons.check_circle_outline,
                          size: 18,
                          color: workplace.isActive ? AppColors.error : AppColors.success,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          workplace.isActive ? 'Desactivar' : 'Activar',
                          style: TextStyle(
                            color: workplace.isActive ? AppColors.error : AppColors.success,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class WorkplaceDialogs {
  static Future<void> confirmReactivate(BuildContext context, WidgetRef ref, String id) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.cardDark,
        title: const Text(
          'Activar lugar de trabajo',
          style: TextStyle(color: AppColors.textWhite),
        ),
        content: const Text(
          '¿Seguro que deseas activar este lugar de trabajo?',
          style: TextStyle(color: AppColors.textMuted),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Cancelar', style: TextStyle(color: AppColors.textMuted)),
          ),
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            style: TextButton.styleFrom(foregroundColor: AppColors.success),
            child: const Text('Activar'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      ref.read(workplaceDeleteProvider.notifier).reactivateWorkplace(id);
    }
  }
}
