import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../authentication/presentation/providers/auth_provider.dart';
import '../../../authentication/data/models/user_model.dart';
import '../../../workplaces/presentation/providers/workplace_notifier.dart';
import '../../../workplaces/data/models/workplace_model.dart';

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
              _buildHeader(user),
              const SizedBox(height: 8),
              _buildEmail(user),
              const SizedBox(height: 12),
              _roleBadge(user.rol),
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

  Widget _buildHeader(UserModel user) {
    return CircleAvatar(
      radius: 48,
      backgroundColor: AppColors.primary,
      child: Text(
        _initials(user),
        style: const TextStyle(
          color: Colors.white,
          fontSize: 28,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  Widget _buildEmail(UserModel user) {
    return Text(
      user.email,
      style: const TextStyle(
        fontSize: 14,
        color: AppColors.textSecondary,
      ),
    );
  }

  Widget _roleBadge(UserRole role) {
    final (Color bg, Color fg, String label) = switch (role) {
      UserRole.admin => (const Color(0xFFFEF3C7), const Color(0xFF92400E), 'Administrador'),
      UserRole.supervisor => (const Color(0xFFDBEAFE), const Color(0xFF1E40AF), 'Supervisor'),
      UserRole.employee => (const Color(0xFFD1FAE5), const Color(0xFF065F46), 'Empleado'),
    };
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: fg,
          fontSize: 13,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  Widget _statusBadge(bool isActive) {
    if (isActive) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
        decoration: BoxDecoration(
          color: const Color(0xFFD1FAE5),
          borderRadius: BorderRadius.circular(20),
        ),
        child: const Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.check_circle, size: 14, color: Color(0xFF065F46)),
            SizedBox(width: 4),
            Text(
              'Activo',
              style: TextStyle(
                color: Color(0xFF065F46),
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      );
    }
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: const Color(0xFFFEE2E2),
        borderRadius: BorderRadius.circular(20),
      ),
      child: const Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.cancel, size: 14, color: Color(0xFF991B1B)),
          SizedBox(width: 4),
          Text(
            'Inactivo',
            style: TextStyle(
              color: Color(0xFF991B1B),
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _sectionCard({
    required String title,
    required IconData titleIcon,
    required List<Widget> items,
  }) {
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: Colors.grey.shade200),
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(titleIcon, size: 18, color: AppColors.primary),
                const SizedBox(width: 8),
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textPrimary,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            ...items.fold<List<Widget>>([], (list, item) {
              if (list.isNotEmpty) {
                list.add(const Divider(height: 20));
              }
              list.add(item);
              return list;
            }),
          ],
        ),
      ),
    );
  }

  Widget _infoRow(IconData icon, String label, String value) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 20, color: AppColors.textSecondary),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: const TextStyle(
                  fontSize: 12,
                  color: AppColors.textSecondary,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                value,
                style: const TextStyle(
                  fontSize: 15,
                  color: AppColors.textPrimary,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _personalInfoCard(UserModel user) {
    return _sectionCard(
      title: 'Información Personal',
      titleIcon: Icons.person_outline,
      items: [
        _infoRow(Icons.person_outline, 'Nombre completo', user.nombreCompleto),
        _infoRow(Icons.email_outlined, 'Correo electrónico', user.email),
        _infoRow(Icons.badge_outlined, 'DNI', user.dni),
        if (user.telefono != null)
          _infoRow(Icons.phone_outlined, 'Teléfono', user.telefono!),
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

    return _sectionCard(
      title: 'Información Laboral',
      titleIcon: Icons.work_outline,
      items: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Icon(Icons.badge_outlined, size: 20, color: AppColors.textSecondary),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Rol',
                    style: TextStyle(
                      fontSize: 12,
                      color: AppColors.textSecondary,
                    ),
                  ),
                  const SizedBox(height: 4),
                  _roleBadge(user.rol),
                ],
              ),
            ),
          ],
        ),
        _infoRow(Icons.business_outlined, 'Lugar de trabajo', workplaceName),
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Icon(Icons.toggle_on_outlined, size: 20, color: AppColors.textSecondary),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Estado',
                    style: TextStyle(
                      fontSize: 12,
                      color: AppColors.textSecondary,
                    ),
                  ),
                  const SizedBox(height: 4),
                  _statusBadge(user.isActive),
                ],
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _systemInfoCard(UserModel user) {
    return _sectionCard(
      title: 'Sistema',
      titleIcon: Icons.settings_outlined,
      items: [
        _infoRow(Icons.calendar_today_outlined, 'Fecha de creación', _formatDate(user.createdAt)),
        if (user.updatedAt != null)
          _infoRow(Icons.update_outlined, 'Última actualización', _formatDate(user.updatedAt!)),
      ],
    );
  }

  String _initials(UserModel user) {
    final first = user.nombre.isNotEmpty ? user.nombre[0] : '';
    final last = user.apellido.isNotEmpty ? user.apellido[0] : '';
    return '$first$last'.toUpperCase();
  }

  String _formatDate(DateTime date) {
    final months = [
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
