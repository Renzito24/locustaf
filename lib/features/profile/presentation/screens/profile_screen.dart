import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../authentication/presentation/providers/auth_provider.dart';
import '../../../authentication/data/models/user_model.dart';
import '../../../workplaces/presentation/providers/workplace_notifier.dart';
import '../../../workplaces/data/models/workplace_model.dart';
import '../widgets/profile_header.dart';
import '../widgets/profile_info_card.dart';
import '../widgets/profile_role_badge.dart';
import '../widgets/profile_status_badge.dart';

class ProfileScreen extends ConsumerWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final userAsync = ref.watch(currentAppUserProvider);
    final workplacesAsync = ref.watch(activeWorkplacesProvider);

    return Padding(
      padding: const EdgeInsets.all(24),
      child: userAsync.when(
        data: (user) {
          if (user == null) {
            return _buildEmptyState();
          }
          return _buildProfile(context, user, workplacesAsync);
        },
        loading: () => const Center(
          child: CircularProgressIndicator(
            valueColor: AlwaysStoppedAnimation<Color>(AppColors.primary),
          ),
        ),
        error: (error, _) => _buildErrorState(error.toString()),
      ),
    );
  }

  Widget _buildProfile(
    BuildContext context,
    UserModel user,
    AsyncValue<List<WorkplaceModel>> workplacesAsync,
  ) {
    return Center(
      child: SingleChildScrollView(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 520),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ProfileHeader(user: user),
              const SizedBox(height: 32),
              _personalInfoCard(user),
              const SizedBox(height: 16),
              _workInfoCard(user, workplacesAsync),
              const SizedBox(height: 16),
              _systemInfoCard(user),
            ],
          ),
        ),
      ),
    );
  }

  Widget _personalInfoCard(UserModel user) {
    return ProfileInfoCard(
      title: 'Información Personal',
      titleIcon: Icons.person_outline,
      rows: [
        ProfileInfoRow(icon: Icons.person_outline, label: 'Nombre completo', value: user.nombreCompleto),
        ProfileInfoRow(icon: Icons.email_outlined, label: 'Correo electrónico', value: user.email),
        ProfileInfoRow(icon: Icons.badge_outlined, label: 'DNI', value: user.dni),
        if (user.telefono != null)
          ProfileInfoRow(icon: Icons.phone_outlined, label: 'Teléfono', value: user.telefono!),
      ],
    );
  }

  Widget _workInfoCard(
    UserModel user,
    AsyncValue<List<WorkplaceModel>> workplacesAsync,
  ) {
    final workplaceName = workplacesAsync.when(
      data: (workplaces) {
        final w = workplaces.where((w) => w.id == user.lugarDeTrabajoId).firstOrNull;
        return w?.nombre ?? (user.lugarDeTrabajoId != null ? '—' : 'No asignado');
      },
      loading: () => 'Cargando...',
      error: (_, _) => '—',
    );

    return ProfileInfoCard(
      title: 'Información Laboral',
      titleIcon: Icons.work_outline,
      rows: [
        ProfileInfoRow(
          icon: Icons.badge_outlined,
          label: 'Rol',
          child: ProfileRoleBadge(role: user.rol),
        ),
        ProfileInfoRow(icon: Icons.business_outlined, label: 'Lugar de trabajo', value: workplaceName),
        ProfileInfoRow(
          icon: Icons.toggle_on_outlined,
          label: 'Estado',
          child: ProfileStatusBadge(isActive: user.isActive),
        ),
      ],
    );
  }

  Widget _systemInfoCard(UserModel user) {
    return ProfileInfoCard(
      title: 'Sistema',
      titleIcon: Icons.settings_outlined,
      rows: [
        ProfileInfoRow(icon: Icons.calendar_today_outlined, label: 'Fecha de creación', value: _formatDate(user.createdAt)),
        if (user.updatedAt != null)
          ProfileInfoRow(icon: Icons.update_outlined, label: 'Última actualización', value: _formatDate(user.updatedAt!)),
      ],
    );
  }

  String _formatDate(DateTime date) {
    const months = [
      'ene', 'feb', 'mar', 'abr', 'may', 'jun',
      'jul', 'ago', 'sep', 'oct', 'nov', 'dic',
    ];
    return '${date.day} ${months[date.month - 1]} ${date.year}';
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.person_off_outlined, size: 64, color: Colors.grey.shade400),
          const SizedBox(height: 16),
          const Text(
            'No se pudo cargar el perfil',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 4),
          const Text(
            'Iniciá sesión para ver tu perfil.',
            style: TextStyle(color: AppColors.textSecondary),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorState(String message) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.error_outline, size: 64, color: AppColors.error),
          const SizedBox(height: 16),
          const Text(
            'Error al cargar el perfil',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            message,
            textAlign: TextAlign.center,
            style: const TextStyle(color: AppColors.textSecondary),
          ),
        ],
      ),
    );
  }
}
