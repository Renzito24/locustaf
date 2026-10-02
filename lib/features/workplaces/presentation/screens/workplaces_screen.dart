import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/providers/async_action_state.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/models/user_model.dart';
import '../../../authentication/presentation/providers/auth_provider.dart';
import '../providers/workplace_notifier.dart';
import '../providers/workplace_search_provider.dart';
import 'workplaces_screen_components.dart';

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

    ref.listen<AsyncActionState>(workplaceDeleteProvider, (prev, next) {
      if (prev?.status != AsyncActionStatus.loading) return;
      if (next.status == AsyncActionStatus.success) {
        ref.read(workplaceDeleteProvider.notifier).reset();
        ScaffoldMessenger.of(context).showSnackBar(
          AppTheme.successSnackBar('Estado actualizado correctamente'),
        );
      } else if (next.status == AsyncActionStatus.failure) {
        ScaffoldMessenger.of(context).showSnackBar(
          AppTheme.errorSnackBar('Error: ${next.error}'),
        );
      }
    });

    return SingleChildScrollView(
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
                WorkplaceFilterChip(
                  label: 'Todos',
                  isSelected: statusFilter == WorkplaceStatusFilter.all,
                  onTap: () => ref.read(workplaceFilterProvider.notifier).setFilter(
                        WorkplaceStatusFilter.all,
                      ),
                ),
                const SizedBox(width: 8),
                WorkplaceFilterChip(
                  label: 'Activos',
                  isSelected: statusFilter == WorkplaceStatusFilter.active,
                  onTap: () => ref.read(workplaceFilterProvider.notifier).setFilter(
                        WorkplaceStatusFilter.active,
                      ),
                ),
                const SizedBox(width: 8),
                WorkplaceFilterChip(
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
          workplacesAsync.when(
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
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: workplaces.length,
                separatorBuilder: (_, _) => const SizedBox(height: 12),
                itemBuilder: (context, index) =>
                    WorkplaceCard(workplace: workplaces[index], isAdmin: isAdmin),
              );
            },
            loading: () => AppTheme.loadingState(message: 'Cargando lugares...'),
            error: (e, _) => AppTheme.errorState(e.toString()),
          ),
        ],
      ),
    );
  }
}
