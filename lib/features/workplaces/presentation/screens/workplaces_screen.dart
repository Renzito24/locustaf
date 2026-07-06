import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../authentication/data/models/user_model.dart';
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

    ref.listen<AsyncValue<void>>(workplaceDeleteProvider, (prev, next) {
      next.whenOrNull(
        data: (_) {
          ref.read(workplaceDeleteProvider.notifier).reset();
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Estado actualizado correctamente'),
              backgroundColor: AppColors.success,
            ),
          );
        },
        error: (error, _) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Error: $error'),
              backgroundColor: AppColors.error,
              duration: const Duration(seconds: 5),
            ),
          );
        },
      );
    });

    return Padding(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Lugares de trabajo',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textPrimary,
                ),
              ),
              if (isAdmin)
                ElevatedButton.icon(
                  onPressed: () => context.push('/workplaces/create'),
                  icon: const Icon(Icons.add),
                  label: const Text('Nuevo lugar'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.white,
                  ),
                ),
            ],
          ),
          const SizedBox(height: 4),
          const Text(
            'Administra las ubicaciones y unidades organizativas de la empresa.',
            style: TextStyle(
              color: AppColors.textSecondary,
              fontSize: 14,
            ),
          ),
          const SizedBox(height: 16),
          // Search bar
          TextField(
            onChanged: (value) {
              ref.read(workplaceSearchQueryProvider.notifier).updateQuery(value);
            },
            decoration: InputDecoration(
              hintText: 'Buscar por nombre, dirección o descripción...',
              prefixIcon: const Icon(Icons.search),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              suffixIcon: searchQuery.isNotEmpty
                  ? IconButton(
                      icon: const Icon(Icons.clear),
                      onPressed: () {
                        ref.read(workplaceSearchQueryProvider.notifier).clear();
                      },
                    )
                  : null,
            ),
          ),
          const SizedBox(height: 12),
          // Filter chips
          Row(
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
          const SizedBox(height: 16),
          Expanded(
            child: workplacesAsync.when(
              data: (workplaces) {
                if (workplaces.isEmpty) {
                  final hasFiltersOrSearch =
                      searchQuery.isNotEmpty || statusFilter != WorkplaceStatusFilter.all;
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          hasFiltersOrSearch ? Icons.search_off : Icons.business_outlined,
                          size: 64,
                          color: Colors.grey.shade400,
                        ),
                        const SizedBox(height: 16),
                        Text(
                          hasFiltersOrSearch
                              ? 'Sin resultados'
                              : 'No hay lugares de trabajo',
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: AppColors.textPrimary,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          hasFiltersOrSearch
                              ? 'Intenta con otros filtros o términos de búsqueda.'
                              : 'Crea el primer lugar de trabajo para comenzar.',
                          style: const TextStyle(color: AppColors.textSecondary),
                        ),
                      ],
                    ),
                  );
                }
                return ListView.separated(
                  itemCount: workplaces.length,
                  separatorBuilder: (_, _) => const SizedBox(height: 12),
                  itemBuilder: (context, index) =>
                      _WorkplaceCard(workplace: workplaces[index], isAdmin: isAdmin),
                );
              },
              loading: () => const Center(
                child: CircularProgressIndicator(
                  valueColor: AlwaysStoppedAnimation<Color>(AppColors.primary),
                ),
              ),
              error: (e, _) => Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.error_outline, size: 64, color: Colors.grey.shade400),
                    const SizedBox(height: 16),
                    const Text(
                      'Error al cargar lugares de trabajo',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      e.toString(),
                      style: const TextStyle(color: AppColors.textSecondary),
                    ),
                  ],
                ),
              ),
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
      selectedColor: AppColors.primary,
      backgroundColor: AppColors.surface,
      labelStyle: TextStyle(
        color: isSelected ? Colors.white : AppColors.textSecondary,
        fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
        fontSize: 13,
      ),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
      ),
      side: BorderSide(
        color: isSelected ? AppColors.primary : Colors.grey.shade300,
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
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: _isHovered
                ? AppColors.primary.withValues(alpha: 0.5)
                : Colors.grey.shade200,
            width: 1,
          ),
          boxShadow: [
            BoxShadow(
              color: _isHovered
                  ? Colors.black.withValues(alpha: 0.08)
                  : Colors.black.withValues(alpha: 0.03),
              blurRadius: _isHovered ? 12 : 6,
              offset: const Offset(0, 2),
            ),
          ],
        ),
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
                      ? AppColors.primary.withValues(alpha: 0.1)
                      : Colors.grey.withValues(alpha: 0.1),
                ),
                child: Icon(
                  Icons.business,
                  color: workplace.isActive ? AppColors.primary : Colors.grey,
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
                        color: AppColors.textPrimary,
                      ),
                    ),
                    if (workplace.description != null &&
                        workplace.description!.isNotEmpty) ...[
                      const SizedBox(height: 4),
                      Text(
                        workplace.description!,
                        style: const TextStyle(
                          color: AppColors.textSecondary,
                          fontSize: 13,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                    if (workplace.direccion != null &&
                        workplace.direccion!.isNotEmpty) ...[
                      const SizedBox(height: 2),
                      Row(
                        children: [
                          const Icon(Icons.location_on, size: 12, color: AppColors.textSecondary),
                          const SizedBox(width: 4),
                          Flexible(
                            child: Text(
                              workplace.direccion!,
                              style: const TextStyle(
                                color: AppColors.textSecondary,
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
                          color: AppColors.textSecondary,
                          fontSize: 11,
                          fontFamily: 'monospace',
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: workplace.isActive
                      ? AppColors.success.withValues(alpha: 0.1)
                      : AppColors.error.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  workplace.isActive ? 'Activo' : 'Inactivo',
                  style: TextStyle(
                    color: workplace.isActive ? AppColors.success : AppColors.error,
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              if (widget.isAdmin) ...[
                const SizedBox(width: 8),
                PopupMenuButton<String>(
                  icon: const Icon(Icons.more_vert, color: AppColors.textSecondary),
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
                          Icon(Icons.edit_outlined, size: 18),
                          SizedBox(width: 8),
                          Text('Editar'),
                        ],
                      ),
                    ),
                    PopupMenuDivider(),
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
        title: const Text('Activar lugar de trabajo'),
        content: const Text('¿Seguro que deseas activar este lugar de trabajo?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Cancelar'),
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
