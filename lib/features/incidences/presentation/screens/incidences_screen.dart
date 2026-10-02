import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/providers/async_action_state.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../authentication/presentation/providers/auth_provider.dart';
import '../../../employees/presentation/providers/users_provider.dart';
import '../providers/incidences_provider.dart';
import 'incidences_components.dart';

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

    ref.listen<AsyncActionState>(incidenceDeleteProvider, (prev, next) {
      if (prev?.status != AsyncActionStatus.loading) return;
      if (next.status == AsyncActionStatus.success) {
        ref.read(incidenceDeleteProvider.notifier).reset();
        ScaffoldMessenger.of(context).showSnackBar(
          AppTheme.successSnackBar('Incidencia eliminada correctamente'),
        );
      } else if (next.status == AsyncActionStatus.failure) {
        ScaffoldMessenger.of(context).showSnackBar(
          AppTheme.errorSnackBar('Error al eliminar: ${next.error}'),
        );
      }
    });

    ref.listen<AsyncActionState>(incidenceApprovalProvider, (prev, next) {
      if (prev?.status != AsyncActionStatus.loading) return;
      if (next.status == AsyncActionStatus.success) {
        ref.read(incidenceApprovalProvider.notifier).reset();
        ScaffoldMessenger.of(context).showSnackBar(
          AppTheme.successSnackBar('Estado de la incidencia actualizado'),
        );
      } else if (next.status == AsyncActionStatus.failure) {
        ScaffoldMessenger.of(context).showSnackBar(
          AppTheme.errorSnackBar('Error al actualizar el estado: ${next.error}'),
        );
      }
    });

    return CustomScrollView(
      slivers: [
        SliverPadding(
          padding: const EdgeInsets.fromLTRB(24, 24, 24, 0),
          sliver: SliverToBoxAdapter(
            child: IncidencesHeader(
              total: total,
              programadas: programadas,
              enCurso: enCurso,
              finalizadas: finalizadas,
              isAdmin: isAdmin,
            ),
          ),
        ),
        SliverPadding(
          padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
          sliver: IncidencesSliverContent(
            incidences: incidences,
            usersAsync: usersAsync,
            isAdmin: isAdmin,
          ),
        ),
      ],
    );
  }
}
