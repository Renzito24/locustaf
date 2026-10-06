import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/router/app_routes.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../authentication/presentation/providers/auth_provider.dart';
import '../../../incidences/data/models/incidence_model.dart';
import '../../../incidences/presentation/providers/incidences_provider.dart';
import '../../../incidences/presentation/widgets/incidence_card.dart';
import '../../../incidences/presentation/widgets/incidence_detail_dialog.dart';

class EmployeeJustificativosScreen extends ConsumerWidget {
  const EmployeeJustificativosScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(currentUserModelProvider);

    if (user == null) {
      return Padding(
        padding: const EdgeInsets.all(24),
        child: AppTheme.emptyState(
          icon: Icons.person_off_outlined,
          title: 'Usuario no autenticado',
          subtitle: 'Iniciá sesión para ver tus justificativos.',
        ),
      );
    }

    final incidencesAsync = ref.watch(incidencesStreamProvider);

    final incidences = (incidencesAsync.value ?? [])
        .where((i) => i.isActive && i.userId == user.id)
        .toList()
      ..sort((a, b) => b.fechaInicio.compareTo(a.fechaInicio));

    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Mis justificativos', style: AppTheme.headingLg),
          const SizedBox(height: 4),
          Text(
            'Gestioná tus incidencias. El administrador las aprueba o rechaza.',
            style: AppTheme.bodyLg,
          ),
          const SizedBox(height: 24),
          _SectionHeader(
            icon: Icons.warning_amber_outlined,
            title: 'Incidencias',
            onAdd: () => context.push(RoutePaths.employeeCreateIncidence),
          ),
          const SizedBox(height: 12),
          if (incidences.isEmpty)
            AppTheme.emptyState(
              icon: Icons.warning_amber_outlined,
              title: 'Sin incidencias',
              subtitle: 'No tenés incidencias cargadas.',
            )
          else
            ...incidences.map(
              (inc) => Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: IncidenceCard(
                  incidence: inc,
                  employeeName: inc.type.label,
                  onTap: () => IncidenceDetailDialog.show(
                    context,
                    incidence: inc,
                    employeeName: '${user.nombre} ${user.apellido}',
                    employeeEmail: user.email,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  final IconData icon;
  final String title;
  final VoidCallback onAdd;

  const _SectionHeader({
    required this.icon,
    required this.title,
    required this.onAdd,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 18, color: AppColors.gold),
        const SizedBox(width: 8),
        Text(
          title.toUpperCase(),
          style: const TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            letterSpacing: 1.2,
            color: AppColors.textMuted,
          ),
        ),
        const Spacer(),
        FilledButton.icon(
          onPressed: onAdd,
          icon: const Icon(Icons.add, size: 18),
          label: const Text('Nuevo'),
          style: FilledButton.styleFrom(
            backgroundColor: AppColors.gold,
            foregroundColor: Colors.white,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppTheme.radiusSm)),
          ),
        ),
      ],
    );
  }
}
