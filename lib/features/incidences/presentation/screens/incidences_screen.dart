import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/router/app_routes.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/models/user_model.dart';
import '../../../../core/utils/string_utils.dart';
import '../../../authentication/presentation/providers/auth_provider.dart';
import '../../../employees/presentation/providers/users_provider.dart';
import '../../data/models/incidence_model.dart';
import '../providers/incidences_provider.dart';
import '../widgets/incidence_card.dart';
import '../widgets/incidence_detail_dialog.dart';
import '../widgets/incidence_filter_bar.dart';

class IncidencesScreen extends ConsumerWidget {
  const IncidencesScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final incidences = ref.watch(filteredIncidencesProvider);
    final total = ref.watch(totalIncidencesProvider);
    final programadas = ref.watch(programadasCountProvider);
    final enCurso = ref.watch(enCursoCountProvider);
    final finalizadas = ref.watch(finalizadasCountProvider);
    final usersAsync = ref.watch(usersStreamProvider);
    final isAdmin = ref.watch(isAdminProvider);

    ref.listen<AsyncValue<void>>(incidenceDeleteProvider, (prev, next) {
      next.whenOrNull(
        data: (_) {
          ref.read(incidenceDeleteProvider.notifier).reset();
          ScaffoldMessenger.of(context).showSnackBar(
            AppTheme.successSnackBar('Incidencia eliminada correctamente'),
          );
        },
        error: (error, _) {
          ScaffoldMessenger.of(context).showSnackBar(
            AppTheme.errorSnackBar('Error al eliminar: $error'),
          );
        },
      );
    });

    ref.listen<AsyncValue<void>>(incidenceApprovalProvider, (prev, next) {
      next.whenOrNull(
        data: (_) {
          ref.read(incidenceApprovalProvider.notifier).reset();
          ScaffoldMessenger.of(context).showSnackBar(
            AppTheme.successSnackBar('Estado de la incidencia actualizado'),
          );
        },
        error: (error, _) {
          ScaffoldMessenger.of(context).showSnackBar(
            AppTheme.errorSnackBar('Error al actualizar el estado: $error'),
          );
        },
      );
    });

    return Padding(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Incidencias', style: AppTheme.headingLg),
          const SizedBox(height: 4),
          Text(
            'Gestioná las situaciones excepcionales que afectan la asistencia.',
            style: AppTheme.bodyLg,
          ),
          const SizedBox(height: 24),
          _buildIndicatorCards(total, programadas, enCurso, finalizadas),
          const SizedBox(height: 24),
          const IncidenceFilterBar(),
          const SizedBox(height: 16),
          if (isAdmin)
            Align(
              alignment: Alignment.centerRight,
              child: FilledButton.icon(
                onPressed: () => context.push(RoutePaths.createIncidence),
                icon: const Icon(Icons.add, size: 18),
                label: const Text('Nueva incidencia'),
                style: FilledButton.styleFrom(
                  backgroundColor: AppColors.gold,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppTheme.radiusSm)),
                ),
              ),
            ),
          const SizedBox(height: 16),
          Expanded(
            child: _buildContent(context, ref, incidences, usersAsync, isAdmin),
          ),
        ],
      ),
    );
  }

  Widget _buildIndicatorCards(int total, int programadas, int enCurso, int finalizadas) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final crossAxisCount = constraints.maxWidth > 800 ? 4 : (constraints.maxWidth > 500 ? 2 : 1);
        return GridView.count(
          crossAxisCount: crossAxisCount,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          mainAxisSpacing: 16,
          crossAxisSpacing: 16,
          childAspectRatio: 2.2,
          children: [
            _IndicatorCard(icon: Icons.list_alt, label: 'Total incidencias', value: total.toString(), color: AppColors.gold),
            _IndicatorCard(icon: Icons.schedule, label: 'Programadas', value: programadas.toString(), color: AppColors.gold),
            _IndicatorCard(icon: Icons.play_circle, label: 'En curso', value: enCurso.toString(), color: AppColors.success),
            _IndicatorCard(icon: Icons.check_circle, label: 'Finalizadas', value: finalizadas.toString(), color: AppColors.textMuted),
          ],
        );
      },
    );
  }

  Widget _buildContent(
    BuildContext context,
    WidgetRef ref,
    List<IncidenceModel> incidences,
    AsyncValue<List<UserModel>> usersAsync,
    bool isAdmin,
  ) {
    return usersAsync.when(
      data: (users) {
        final userMap = {for (final u in users) u.id: u};

        if (incidences.isEmpty) {
          return AppTheme.emptyState(
            icon: Icons.warning_amber_outlined,
            title: 'Sin incidencias',
            subtitle: 'No hay incidencias para los filtros seleccionados.',
          );
        }

        return LayoutBuilder(
          builder: (context, constraints) {
            if (constraints.maxWidth < 800) {
              return ListView.separated(
                padding: const EdgeInsets.only(bottom: 24),
                itemCount: incidences.length,
                separatorBuilder: (_, _) => const SizedBox(height: 8),
                itemBuilder: (context, index) {
                  final inc = incidences[index];
                  final user = userMap[inc.userId];
                  return IncidenceCard(
                    incidence: inc,
                    employeeName: user?.nombreCompleto ?? 'Usuario ${StringUtils.safePrefix(inc.userId, 6)}',
                    onTap: () => IncidenceDetailDialog.show(
                      context,
                      incidence: inc,
                      employeeName: user?.nombreCompleto ?? 'Desconocido',
                      employeeEmail: user?.email ?? '',
                    ),
                    onDelete: isAdmin ? () => _confirmDelete(context, ref, inc) : null,
                  );
                },
              );
            }

            return SingleChildScrollView(
              scrollDirection: Axis.vertical,
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: DataTable(
                columnSpacing: 20,
                headingRowColor: WidgetStateProperty.all(AppColors.gold.withValues(alpha: 0.1)),
                columns: [
                  const DataColumn(label: Text('Empleado', style: TextStyle(fontWeight: FontWeight.bold, color: AppColors.gold))),
                  const DataColumn(label: Text('Tipo', style: TextStyle(fontWeight: FontWeight.bold, color: AppColors.gold))),
                  const DataColumn(label: Text('Inicio', style: TextStyle(fontWeight: FontWeight.bold, color: AppColors.gold))),
                  const DataColumn(label: Text('Fin', style: TextStyle(fontWeight: FontWeight.bold, color: AppColors.gold))),
                  const DataColumn(label: Text('Estado', style: TextStyle(fontWeight: FontWeight.bold, color: AppColors.gold))),
                  if (isAdmin) const DataColumn(label: Text('Acciones', style: TextStyle(fontWeight: FontWeight.bold, color: AppColors.gold))),
                ],
                rows: incidences.map((inc) {
                  final user = userMap[inc.userId];
                  final name = user?.nombreCompleto ?? 'Usuario ${inc.userId.substring(0, 6)}';
                  return DataRow(
                    onSelectChanged: (_) => IncidenceDetailDialog.show(
                      context,
                      incidence: inc,
                      employeeName: name,
                      employeeEmail: user?.email ?? '',
                    ),
                    cells: [
                      DataCell(Text(name, style: const TextStyle(color: AppColors.textWhite))),
                      DataCell(Text(inc.type.label, style: const TextStyle(color: AppColors.textMuted))),
                      DataCell(Text(_formatDate(inc.fechaInicio), style: const TextStyle(color: AppColors.textMuted))),
                      DataCell(Text(_formatDate(inc.fechaFin), style: const TextStyle(color: AppColors.textMuted))),
                      DataCell(_buildEstadoChip(inc.state)),
                      if (isAdmin)
                        DataCell(Row(
                          children: [
                            IconButton(
                              icon: const Icon(Icons.edit, size: 18, color: AppColors.gold),
                              onPressed: () => context.push(RoutePaths.editIncidence, extra: inc),
                              tooltip: 'Editar',
                              visualDensity: VisualDensity.compact,
                            ),
                            IconButton(
                              icon: const Icon(Icons.delete_outline, size: 18, color: AppColors.error),
                              onPressed: () => _confirmDelete(context, ref, inc),
                              tooltip: 'Eliminar',
                              visualDensity: VisualDensity.compact,
                            ),
                          ],
                        )),
                    ],
                  );
                }).toList(),
              ),
            ),
          );
        },
      );
      },
      loading: () => AppTheme.loadingState(),
      error: (_, _) => AppTheme.errorState('No se pudieron obtener los datos de los empleados.'),
    );
  }

  String _formatDate(DateTime dt) {
    return '${dt.year}-${dt.month.toString().padLeft(2, '0')}-${dt.day.toString().padLeft(2, '0')}';
  }

  Widget _buildEstadoChip(IncidenceState state) {
    switch (state) {
      case IncidenceState.programada:
        return AppTheme.badge(label: state.label, bgColor: AppColors.gold.withValues(alpha: 0.15), textColor: AppColors.gold);
      case IncidenceState.enCurso:
        return AppTheme.badge(label: state.label, bgColor: AppColors.success.withValues(alpha: 0.15), textColor: AppColors.success);
      case IncidenceState.finalizada:
        return AppTheme.badge(label: state.label, bgColor: AppColors.textMuted.withValues(alpha: 0.15), textColor: AppColors.textMuted);
    }
  }

  void _confirmDelete(BuildContext context, WidgetRef ref, IncidenceModel inc) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.cardDark,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppTheme.radiusLg),
          side: BorderSide(color: AppColors.gold.withValues(alpha: 0.3)),
        ),
        title: Text('Eliminar incidencia', style: AppTheme.headingMd),
        content: Text(
          '¿Eliminar la incidencia de tipo "${inc.type.label}"?',
          style: AppTheme.bodyLg,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Cancelar', style: TextStyle(color: AppColors.textMuted)),
          ),
          FilledButton(
            onPressed: () {
              Navigator.of(ctx).pop();
              ref.read(incidenceDeleteProvider.notifier).softDelete(inc.id);
            },
            style: FilledButton.styleFrom(
              backgroundColor: AppColors.error,
              foregroundColor: Colors.white,
            ),
            child: const Text('Eliminar'),
          ),
        ],
      ),
    );
  }
}

class _IndicatorCard extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final Color color;

  const _IndicatorCard({required this.icon, required this.label, required this.value, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: AppTheme.cardDecoration(),
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: color.withValues(alpha: 0.15),
            ),
            child: Icon(icon, color: color, size: 20),
          ),
          const SizedBox(width: 12),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(value, style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: color)),
              Text(label, style: const TextStyle(fontSize: 13, color: AppColors.textMuted)),
            ],
          ),
        ],
      ),
    );
  }
}
