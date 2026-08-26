import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/models/user_model.dart';
import '../../../authentication/presentation/providers/auth_provider.dart';
import '../../data/models/workplace_model.dart';
import '../providers/workplace_notifier.dart';
import '../providers/workplace_search_provider.dart';

class WorkplacesScreen extends ConsumerWidget {
  const WorkplacesScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final workplacesAsync = ref.watch(filteredWorkplacesProvider);
    final searchQuery = ref.watch(workplaceSearchQueryProvider);
    final statusFilter = ref.watch(workplaceFilterProvider);
    final role = ref.watch(userRoleProvider);
    final isAdmin = role == UserRole.admin;
    final isMobile = AppTheme.isMobile(context);

    ref.listen<AsyncValue<void>>(workplaceDeleteProvider, (prev, next) {
      next.whenOrNull(
        data: (_) {
          ref.read(workplaceDeleteProvider.notifier).reset();
          ScaffoldMessenger.of(context).showSnackBar(
            AppTheme.successSnackBar('Estado actualizado correctamente'),
          );
        },
        error: (error, _) {
          ScaffoldMessenger.of(context).showSnackBar(
            AppTheme.errorSnackBar('Error: $error'),
          );
        },
      );
    });

    return Padding(
      padding: EdgeInsets.all(isMobile ? 16.0 : 24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Lugares de trabajo',
                style: AppTheme.headingLg,
              ),
              if (isAdmin)
                DecoratedBox(
                  decoration: BoxDecoration(
                    gradient: AppTheme.goldGradient,
                    borderRadius: BorderRadius.circular(AppTheme.radiusLg),
                  ),
                  child: Material(
                    color: Colors.transparent,
                    child: InkWell(
                      onTap: () => context.push('/workplaces/create'),
                      borderRadius: BorderRadius.circular(AppTheme.radiusLg),
                      child: Padding(
                        padding: EdgeInsets.symmetric(
                          horizontal: isMobile ? 12 : 20,
                          vertical: 12,
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(Icons.add, color: Color(0xFF0B0B0F), size: 18),
                            const SizedBox(width: 6),
                            Text(
                              'Nuevo lugar',
                              style: TextStyle(
                                color: const Color(0xFF0B0B0F),
                                fontWeight: FontWeight.w600,
                                fontSize: isMobile ? 13 : 14,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            'Administra las ubicaciones y unidades organizativas de la empresa.',
            style: AppTheme.bodyLg,
          ),
          const SizedBox(height: 16),
          TextField(
            onChanged: (value) {
              ref.read(workplaceSearchQueryProvider.notifier).updateQuery(value);
            },
            style: const TextStyle(color: AppColors.textWhite),
            decoration: AppTheme.inputDecoration(
              label: 'Buscar por nombre, dirección o descripción...',
              icon: Icons.search,
            ).copyWith(
              suffixIcon: searchQuery.isNotEmpty
                  ? IconButton(
                      icon: const Icon(Icons.clear, color: AppColors.textMuted),
                      onPressed: () {
                        ref.read(workplaceSearchQueryProvider.notifier).clear();
                      },
                    )
                  : null,
            ),
          ),
          const SizedBox(height: 12),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                _buildFilterChip(
                  label: 'Todos',
                  isSelected: statusFilter == WorkplaceStatusFilter.all,
                  onTap: () => ref.read(workplaceFilterProvider.notifier).setFilter(
                        WorkplaceStatusFilter.all,
                      ),
                ),
                const SizedBox(width: 8),
                _buildFilterChip(
                  label: 'Activos',
                  isSelected: statusFilter == WorkplaceStatusFilter.active,
                  onTap: () => ref.read(workplaceFilterProvider.notifier).setFilter(
                        WorkplaceStatusFilter.active,
                      ),
                ),
                const SizedBox(width: 8),
                _buildFilterChip(
                  label: 'Inactivos',
                  isSelected: statusFilter == WorkplaceStatusFilter.inactive,
                  onTap: () => ref.read(workplaceFilterProvider.notifier).setFilter(
                        WorkplaceStatusFilter.inactive,
                      ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          Expanded(
            child: workplacesAsync.when(
              data: (workplaces) {
                if (workplaces.isEmpty) {
                  final hasFiltersOrSearch =
                      searchQuery.isNotEmpty || statusFilter != WorkplaceStatusFilter.all;
                  return AppTheme.emptyState(
                    icon: hasFiltersOrSearch
                        ? Icons.search_off
                        : Icons.business_outlined,
                    title: hasFiltersOrSearch
                        ? 'Sin resultados'
                        : 'No hay lugares de trabajo',
                    subtitle: hasFiltersOrSearch
                        ? 'Intenta con otros filtros o términos de búsqueda.'
                        : 'Crea el primer lugar de trabajo para comenzar.',
                  );
                }
                return ListView.separated(
                  itemCount: workplaces.length,
                  separatorBuilder: (_, _) => const SizedBox(height: 12),
                  itemBuilder: (context, index) =>
                      _WorkplaceCard(workplace: workplaces[index], isAdmin: isAdmin),
                );
              },
              loading: () => AppTheme.loadingState(message: 'Cargando lugares...'),
              error: (e, _) => AppTheme.errorState(e.toString()),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterChip({
    required String label,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
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

class _WorkplaceCard extends ConsumerStatefulWidget {
  final WorkplaceModel workplace;
  final bool isAdmin;

  const _WorkplaceCard({
    required this.workplace,
    required this.isAdmin,
  });

  @override
  ConsumerState<_WorkplaceCard> createState() => _WorkplaceCardState();
}

class _WorkplaceCardState extends ConsumerState<_WorkplaceCard> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    final workplace = widget.workplace;

    return MouseRegion(
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        decoration: AppTheme.cardDecoration(isHovered: _isHovered),
        child: Padding(
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
                    if (workplace.latitud != null && workplace.longitud != null) ...[
                      const SizedBox(height: 2),
                      Text(
                        '${workplace.latitud!.toStringAsFixed(4)}, ${workplace.longitud!.toStringAsFixed(4)}',
                        style: const TextStyle(
                          color: AppColors.textMuted,
                          fontSize: 11,
                          fontFamily: 'monospace',
                        ),
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
                          _confirmReactivate(context, workplace.id);
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
      ),
    );
  }

  Future<void> _confirmReactivate(BuildContext context, String id) async {
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
