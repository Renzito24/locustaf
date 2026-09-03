import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/models/user_model.dart';
import '../../../../core/providers/data_providers.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/utils/string_utils.dart';
import '../../../authentication/presentation/providers/auth_provider.dart';
import '../../../workplaces/presentation/providers/workplace_notifier.dart';
import '../../data/models/attendance_model.dart';
import '../providers/attendance_notifier.dart';

class AttendanceScreen extends ConsumerWidget {
  const AttendanceScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authUser = ref.watch(currentUserProvider);
    final userId = authUser?.uid;

    final actionState = ref.watch(attendanceActionProvider);

    ref.listen<AttendanceActionState>(attendanceActionProvider, (prev, next) {
      if (prev?.status == next.status) return;
      if (next.status == AttendanceActionStatus.success) {
        ScaffoldMessenger.of(context).showSnackBar(
          AppTheme.successSnackBar(next.message ?? 'Operación exitosa'),
        );
      } else if (next.status == AttendanceActionStatus.error) {
        ScaffoldMessenger.of(context).showSnackBar(
          AppTheme.errorSnackBar(next.message ?? 'Error'),
        );
      }
    });

    if (userId == null) {
      return Center(
        child: Text(
          'Usuario no autenticado',
          style: AppTheme.bodyLg.copyWith(color: AppColors.textMuted),
        ),
      );
    }

    final isAdmin = ref.watch(isAdminProvider);
    if (isAdmin) {
      return const _AdminAttendanceView();
    }

    final activeAttendanceAsync = ref.watch(activeAttendanceProvider(userId));
    final attendancesAsync = ref.watch(attendancesByUserProvider(userId));
    final orphaned = ref.watch(orphanedAttendancesProvider);
    final isActionLoading = actionState.status == AttendanceActionStatus.loading;

    final myOrphaned = orphaned.where((a) => a.userId == userId).toList();

    return Padding(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Asistencia', style: AppTheme.headingLg),
          const SizedBox(height: 4),
          Text(
            'Registrá tu ingreso y salida del trabajo.',
            style: AppTheme.bodyLg,
          ),
          const SizedBox(height: 24),
          if (myOrphaned.isNotEmpty) ...[
            _buildOrphanedCard(context, ref, myOrphaned.first, userId, isActionLoading),
            const SizedBox(height: 16),
          ],
          activeAttendanceAsync.when(
            data: (active) => _buildActiveSection(context, ref, active, userId, isActionLoading),
            loading: () => AppTheme.loadingState(message: 'Cargando asistencia...'),
            error: (e, _) => AppTheme.errorState('Error al cargar: $e'),
          ),
          const SizedBox(height: 24),
          Text('Historial', style: AppTheme.headingMd),
          const SizedBox(height: 12),
          Expanded(
            child: attendancesAsync.when(
              data: (list) => _buildHistoryList(list, ref),
              loading: () => AppTheme.loadingState(message: 'Cargando historial...'),
              error: (e, _) => AppTheme.errorState('Error al cargar: $e'),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActiveSection(
    BuildContext context,
    WidgetRef ref,
    AttendanceModel? active,
    String userId,
    bool isActionLoading,
  ) {
    if (active == null) {
      return Container(
        decoration: AppTheme.cardDecoration(),
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            Container(
              width: 64,
              height: 64,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: AppColors.gold.withValues(alpha: 0.12),
              ),
              child: Icon(
                Icons.login,
                size: 32,
                color: AppColors.gold.withValues(alpha: 0.8),
              ),
            ),
            const SizedBox(height: 16),
            const Text(
              'No has iniciado tu jornada',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: AppColors.textWhite,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Para registrar tu ingreso, necesitás tener el GPS activado y estar en tu lugar de trabajo.',
              textAlign: TextAlign.center,
              style: AppTheme.bodyMd,
            ),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              child: DecoratedBox(
                decoration: BoxDecoration(
                  gradient: AppTheme.goldGradient,
                  borderRadius: BorderRadius.circular(AppTheme.radiusLg),
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.gold.withValues(alpha: 0.3),
                      blurRadius: 12,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: ElevatedButton.icon(
                  onPressed: isActionLoading
                      ? null
                      : () {
                          ref.read(attendanceActionProvider.notifier).checkIn(userId);
                        },
                  icon: isActionLoading
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : const Icon(Icons.login),
                  label: Text(isActionLoading ? 'Verificando ubicación...' : 'Iniciar jornada'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.transparent,
                    shadowColor: Colors.transparent,
                    foregroundColor: Colors.white,
                    disabledBackgroundColor: Colors.transparent,
                    disabledForegroundColor: Colors.white60,
                    padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
                    textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(AppTheme.radiusLg),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      );
    }

    final workplaceAsync = ref.watch(activeWorkplacesProvider);
    String? workplaceName;
    workplaceAsync.whenData((list) {
      final found = list.where((w) => w.id == active.workplaceId).toList();
      if (found.isNotEmpty) {
        workplaceName = found.first.nombre;
      }
    });

    return Container(
      decoration: AppTheme.cardDecoration(),
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: AppColors.success.withValues(alpha: 0.1),
                ),
                child: const Icon(Icons.access_time, color: AppColors.success, size: 20),
              ),
              const SizedBox(width: 12),
              const Text(
                'Jornada activa',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  color: AppColors.success,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          _infoRow('Inicio', _formatDateTime(active.checkInTime)),
          if (workplaceName != null) ...[
            const SizedBox(height: 8),
            _infoRow('Lugar', workplaceName!),
          ],
          if (active.checkInLatitud != null && active.checkInLongitud != null) ...[
            const SizedBox(height: 8),
            _infoRow('Ubicación',
                '${active.checkInLatitud!.toStringAsFixed(6)}, ${active.checkInLongitud!.toStringAsFixed(6)}'),
          ],
          const SizedBox(height: 20),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: isActionLoading
                  ? null
                  : () {
                      ref.read(attendanceActionProvider.notifier).checkOut(active.id, userId);
                    },
              icon: isActionLoading
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  : const Icon(Icons.logout),
              label: Text(isActionLoading ? 'Finalizando...' : 'Finalizar jornada'),
              style: AppTheme.primaryButtonStyle(isLoading: isActionLoading).copyWith(
                backgroundColor: WidgetStateProperty.all(
                  isActionLoading
                      ? AppColors.warning.withValues(alpha: 0.6)
                      : AppColors.warning,
                ),
                foregroundColor: WidgetStateProperty.all(Colors.white),
                textStyle: WidgetStateProperty.all(
                  const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                ),
                padding: WidgetStateProperty.all(
                  const EdgeInsets.symmetric(vertical: 16),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildOrphanedCard(
    BuildContext context,
    WidgetRef ref,
    AttendanceModel orphaned,
    String userId,
    bool isActionLoading,
  ) {
    return Container(
      decoration: AppTheme.cardDecoration(),
      padding: const EdgeInsets.all(20),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: AppColors.warning.withValues(alpha: 0.12),
            ),
            child: const Icon(Icons.warning_amber_rounded, color: AppColors.warning, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Jornada huérfana detectada',
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: AppColors.warning,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Iniciaste tu jornada el ${_formatDateTime(orphaned.checkInTime)} y superó el horario de fin sin registrar salida.',
                  style: AppTheme.bodyMd,
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          OutlinedButton.icon(
            onPressed: isActionLoading
                ? null
                : () {
                    ref.read(attendanceActionProvider.notifier)
                        .finalizeOrphaned(orphaned.id, userId);
                  },
            icon: const Icon(Icons.check_circle_outline, size: 18),
            label: const Text('Finalizar'),
            style: OutlinedButton.styleFrom(
              foregroundColor: AppColors.warning,
              side: const BorderSide(color: AppColors.warning),
            ),
          ),
        ],
      ),
    );
  }

  Widget _infoRow(String label, String value) {
    return Row(
      children: [
        Text(
          '$label: ',
          style: AppTheme.bodyMd,
        ),
        Expanded(
          child: Text(
            value,
            style: const TextStyle(
              fontWeight: FontWeight.w600,
              color: AppColors.textWhite,
            ),
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }

  Widget _buildHistoryList(List<AttendanceModel> list, WidgetRef ref) {
    if (list.isEmpty) {
      return AppTheme.emptyState(
        icon: Icons.history,
        title: 'Sin registros de asistencia',
        subtitle: 'Aún no se registraron jornadas.',
      );
    }

    final workplaceMap = <String, String>{};
    ref.watch(activeWorkplacesProvider).whenData((list) {
      for (final w in list) {
        workplaceMap[w.id] = w.nombre;
      }
    });

    return ListView.separated(
      itemCount: list.length,
      separatorBuilder: (_, _) => Divider(
        height: 1,
        color: AppColors.gold.withValues(alpha: 0.08),
      ),
      itemBuilder: (context, index) {
        final record = list[index];
        final isActive = record.status == AttendanceStatus.active;
        final workplaceName = record.workplaceId != null
            ? workplaceMap[record.workplaceId!]
            : null;
        return ListTile(
          leading: Icon(
            isActive ? Icons.play_circle_outline : Icons.check_circle_outline,
            color: isActive ? AppColors.success : AppColors.textMuted,
          ),
          title: Text(
            record.date,
            style: TextStyle(
              fontWeight: isActive ? FontWeight.w600 : FontWeight.normal,
              color: AppColors.textWhite,
            ),
          ),
          subtitle: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Entrada: ${_formatTime(record.checkInTime)}'
                '${record.checkOutTime != null ? '  |  Salida: ${_formatTime(record.checkOutTime!)}' : ''}'
                '${record.durationMinutes != null ? '  |  ${_formatDuration(record.durationMinutes!)}' : ''}',
                style: AppTheme.bodyMd,
              ),
              if (workplaceName != null && !isActive)
                Text(
                  'Lugar: $workplaceName',
                  style: AppTheme.bodyMd.copyWith(
                    fontSize: 11,
                    color: AppColors.textMuted.withValues(alpha: 0.7),
                  ),
                ),
            ],
          ),
          isThreeLine: workplaceName != null && !isActive,
        );
      },
    );
  }

  String _formatDateTime(DateTime dt) {
    return '${dt.day}/${dt.month}/${dt.year} ${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';
  }

  String _formatTime(DateTime dt) {
    return '${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';
  }

  String _formatDuration(int minutes) {
    if (minutes < 60) return '${minutes}min';
    final h = minutes ~/ 60;
    final m = minutes % 60;
    return '${h}h ${m}min';
  }
}

/// Vista de asistencia para administradores: consulta las asistencias de una
/// fecha (con navegación por flechas) y permite registrar ingresos manuales
/// de empleados que no pueden registrarse por sí mismos.
class _AdminAttendanceView extends ConsumerStatefulWidget {
  const _AdminAttendanceView();

  @override
  ConsumerState<_AdminAttendanceView> createState() =>
      _AdminAttendanceViewState();
}

class _AdminAttendanceViewState extends ConsumerState<_AdminAttendanceView> {
  DateTime _selectedDate = DateTime.now();

  String get _dateKey {
    return '${_selectedDate.year}-${_selectedDate.month.toString().padLeft(2, '0')}-${_selectedDate.day.toString().padLeft(2, '0')}';
  }

  bool get _isToday {
    final now = DateTime.now();
    return now.year == _selectedDate.year &&
        now.month == _selectedDate.month &&
        now.day == _selectedDate.day;
  }

  void _changeDate(int days) {
    setState(() {
      _selectedDate = _selectedDate.add(Duration(days: days));
    });
  }

  @override
  Widget build(BuildContext context) {
    final usersAsync = ref.watch(allUsersStreamProvider);
    final attendancesAsync = ref.watch(allAttendancesStreamProvider);
    final workplacesAsync = ref.watch(allWorkplacesStreamProvider);
    final actionState = ref.watch(attendanceActionProvider);
    final isActionLoading =
        actionState.status == AttendanceActionStatus.loading;

    ref.listen<AttendanceActionState>(attendanceActionProvider, (prev, next) {
      if (prev?.status == next.status) return;
      if (next.status == AttendanceActionStatus.success) {
        ScaffoldMessenger.of(context).showSnackBar(
          AppTheme.successSnackBar(next.message ?? 'Operación exitosa'),
        );
      } else if (next.status == AttendanceActionStatus.error) {
        ScaffoldMessenger.of(context).showSnackBar(
          AppTheme.errorSnackBar(next.message ?? 'Error'),
        );
      }
    });

    final users = usersAsync.value ?? [];
    final attendances = attendancesAsync.value ?? [];
    final workplaces = workplacesAsync.value ?? [];

    final dayAttendances = attendances
        .where((a) => a.date == _dateKey)
        .toList()
      ..sort((a, b) => b.checkInTime.compareTo(a.checkInTime));

    final workplaceMap = {for (final w in workplaces) w.id: w.nombre};
    final userMap = {for (final u in users) u.id: u};

    return SingleChildScrollView(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Asistencia', style: AppTheme.headingLg),
          const SizedBox(height: 4),
          Text(
            'Consultá las asistencias del día y registrá ingresos manuales.',
            style: AppTheme.bodyLg,
          ),
          const SizedBox(height: 24),
          Container(
            decoration: AppTheme.cardDecoration(),
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
            child: Row(
              children: [
                IconButton(
                  onPressed: () => _changeDate(-1),
                  icon: const Icon(Icons.chevron_left, color: AppColors.gold),
                  tooltip: 'Día anterior',
                ),
                Expanded(
                  child: Column(
                    children: [
                      Text(
                        _formatDate(_selectedDate),
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w600,
                          color: AppColors.textWhite,
                        ),
                      ),
                      if (_isToday) ...[
                        const SizedBox(height: 2),
                        Text('Hoy', style: AppTheme.bodyMd),
                      ],
                    ],
                  ),
                ),
                IconButton(
                  onPressed: () => _changeDate(1),
                  icon: const Icon(Icons.chevron_right, color: AppColors.gold),
                  tooltip: 'Día siguiente',
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            child: FilledButton.icon(
              onPressed: isActionLoading
                  ? null
                  : () => _showManualCheckInDialog(users),
              icon: isActionLoading
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  : const Icon(Icons.person_add_alt_1),
              label: Text(isActionLoading
                  ? 'Registrando...'
                  : 'Registrar ingreso manual'),
              style: FilledButton.styleFrom(
                backgroundColor: AppColors.gold,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 14),
              ),
            ),
          ),
          const SizedBox(height: 24),
          Text('Asistencias del día', style: AppTheme.headingMd),
          const SizedBox(height: 12),
          if (dayAttendances.isEmpty)
            AppTheme.emptyState(
              icon: Icons.event_busy,
              title: 'Sin asistencias',
              subtitle: 'No hay registros para esta fecha.',
            )
          else
            ...dayAttendances.map((a) {
              final user = userMap[a.userId];
              final name = user?.nombreCompleto ??
                  'Usuario ${StringUtils.safePrefix(a.userId, 6)}';
              final workplaceName =
                  a.workplaceId != null ? workplaceMap[a.workplaceId!] : null;
              final isActive = a.status == AttendanceStatus.active;
              return Container(
                margin: const EdgeInsets.only(bottom: 8),
                decoration: AppTheme.cardDecoration(),
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    Icon(
                      isActive
                          ? Icons.play_circle_outline
                          : Icons.check_circle_outline,
                      color:
                          isActive ? AppColors.success : AppColors.textMuted,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            name,
                            style: const TextStyle(
                              fontWeight: FontWeight.w600,
                              color: AppColors.textWhite,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Entrada: ${_formatTime(a.checkInTime)}'
                            '${a.checkOutTime != null ? '  |  Salida: ${_formatTime(a.checkOutTime!)}' : ''}'
                            '${a.durationMinutes != null ? '  |  ${_formatDuration(a.durationMinutes!)}' : ''}',
                            style: AppTheme.bodyMd,
                          ),
                          if (workplaceName != null)
                            Text(
                              'Lugar: $workplaceName',
                              style: AppTheme.bodyMd.copyWith(
                                fontSize: 11,
                                color: AppColors.textMuted
                                    .withValues(alpha: 0.7),
                              ),
                            ),
                        ],
                      ),
                    ),
                    if (isActive)
                      Text(
                        'Activo',
                        style: TextStyle(
                          color: AppColors.success,
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                  ],
                ),
              );
            }),
        ],
      ),
    );
  }

  Future<void> _showManualCheckInDialog(List<UserModel> users) async {
    final eligible = users
        .where((u) =>
            u.isActive &&
            !u.isDeleted &&
            u.rol != UserRole.superadmin &&
            u.lugarDeTrabajoId != null &&
            u.lugarDeTrabajoId!.isNotEmpty)
        .toList();

    if (eligible.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        AppTheme.errorSnackBar(
            'No hay empleados activos con lugar de trabajo asignado.'),
      );
      return;
    }

    await showDialog<void>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        backgroundColor: AppColors.cardDark,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppTheme.radiusXl),
          side: BorderSide(color: AppColors.gold.withValues(alpha: 0.18)),
        ),
        title: const Text(
          'Registrar ingreso manual',
          style: TextStyle(color: AppColors.textWhite),
        ),
        content: SizedBox(
          width: double.maxFinite,
          child: ListView.separated(
            shrinkWrap: true,
            itemCount: eligible.length,
            separatorBuilder: (_, _) => Divider(
              height: 1,
              color: AppColors.gold.withValues(alpha: 0.08),
            ),
            itemBuilder: (context, index) {
              final user = eligible[index];
              return ListTile(
                leading: const Icon(Icons.person_outline,
                    color: AppColors.gold),
                title: Text(
                  user.nombreCompleto,
                  style: const TextStyle(color: AppColors.textWhite),
                ),
                subtitle: Text(
                  user.email,
                  style: AppTheme.bodyMd,
                ),
                onTap: () {
                  Navigator.of(dialogContext).pop();
                  ref
                      .read(attendanceActionProvider.notifier)
                      .manualCheckIn(user.id);
                },
              );
            },
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(),
            child: const Text('Cancelar',
                style: TextStyle(color: AppColors.textMuted)),
          ),
        ],
      ),
    );
  }

  String _formatDate(DateTime dt) {
    const months = [
      'enero', 'febrero', 'marzo', 'abril', 'mayo', 'junio',
      'julio', 'agosto', 'septiembre', 'octubre', 'noviembre', 'diciembre',
    ];
    return '${dt.day} de ${months[dt.month - 1]} de ${dt.year}';
  }

  String _formatTime(DateTime dt) {
    return '${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';
  }

  String _formatDuration(int minutes) {
    if (minutes < 60) return '${minutes}min';
    final h = minutes ~/ 60;
    final m = minutes % 60;
    return '${h}h ${m}min';
  }
}
