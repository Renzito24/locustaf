import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/constants/app_colors.dart';
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
          SnackBar(
            content: Text(next.message ?? 'Operación exitosa'),
            backgroundColor: AppColors.success,
            behavior: SnackBarBehavior.floating,
          ),
        );
      } else if (next.status == AttendanceActionStatus.error) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(next.message ?? 'Error'),
            backgroundColor: AppColors.error,
            behavior: SnackBarBehavior.floating,
            duration: const Duration(seconds: 6),
            action: next.message?.contains('GPS') == true || next.message?.contains('permiso') == true || next.message?.contains('precisión') == true
                ? SnackBarAction(
                    label: 'Cerrar',
                    textColor: Colors.white,
                    onPressed: () {},
                  )
                : null,
          ),
        );
      }
    });

    if (userId == null) {
      return const Center(child: Text('Usuario no autenticado'));
    }

    final activeAttendanceAsync = ref.watch(activeAttendanceProvider(userId));
    final attendancesAsync = ref.watch(attendancesByUserProvider(userId));
    final isActionLoading = actionState.status == AttendanceActionStatus.loading;

    return Padding(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Asistencia',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 4),
          const Text(
            'Registrá tu ingreso y salida del trabajo.',
            style: TextStyle(color: AppColors.textSecondary, fontSize: 14),
          ),
          const SizedBox(height: 24),
          activeAttendanceAsync.when(
            data: (active) => _buildActiveSection(context, ref, active, userId, isActionLoading),
            loading: () => const Center(
              child: CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(AppColors.primary),
              ),
            ),
            error: (e, _) => Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.error_outline, size: 48, color: Colors.grey.shade400),
                  const SizedBox(height: 12),
                  Text('Error al cargar: $e',
                      style: const TextStyle(color: AppColors.textSecondary)),
                ],
              ),
            ),
          ),
          const SizedBox(height: 24),
          const Text(
            'Historial',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 12),
          Expanded(
            child: attendancesAsync.when(
              data: (list) => _buildHistoryList(list),
              loading: () => const Center(
                child: CircularProgressIndicator(
                  valueColor: AlwaysStoppedAnimation<Color>(AppColors.primary),
                ),
              ),
              error: (e, _) => Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.error_outline, size: 48, color: Colors.grey.shade400),
                    const SizedBox(height: 12),
                    Text('Error al cargar: $e',
                        style: const TextStyle(color: AppColors.textSecondary)),
                  ],
                ),
              ),
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
      return Card(
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: BorderSide(color: Colors.grey.shade200),
        ),
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            children: [
              Icon(Icons.login, size: 48, color: AppColors.primary.withValues(alpha: 0.7)),
              const SizedBox(height: 16),
              const Text(
                'No has iniciado tu jornada',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                'Para registrar tu ingreso, necesitás tener el GPS activado y estar en tu lugar de trabajo.',
                textAlign: TextAlign.center,
                style: TextStyle(color: AppColors.textSecondary, fontSize: 13),
              ),
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
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
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.white,
                    disabledBackgroundColor: AppColors.primary.withValues(alpha: 0.6),
                    disabledForegroundColor: Colors.white70,
                    padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
                    textStyle: const TextStyle(fontSize: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                ),
              ),
            ],
          ),
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
                Text(
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
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.warning,
                  foregroundColor: Colors.white,
                  disabledBackgroundColor: AppColors.warning.withValues(alpha: 0.6),
                  disabledForegroundColor: Colors.white70,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  textStyle: const TextStyle(fontSize: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _infoRow(String label, String value) {
    return Row(
      children: [
        Text(
          '$label: ',
          style: const TextStyle(color: AppColors.textSecondary),
        ),
        Expanded(
          child: Text(
            value,
            style: const TextStyle(
              fontWeight: FontWeight.w600,
              color: AppColors.textPrimary,
            ),
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }

  Widget _buildHistoryList(List<AttendanceModel> list) {
    if (list.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.history, size: 48, color: Colors.grey.shade400),
            const SizedBox(height: 12),
            const Text(
              'Sin registros de asistencia',
              style: TextStyle(color: AppColors.textSecondary, fontSize: 16),
            ),
          ],
        ),
      );
    }

    return ListView.separated(
      itemCount: list.length,
      separatorBuilder: (_, _) => const Divider(height: 1),
      itemBuilder: (context, index) {
        final record = list[index];
        final isActive = record.status == AttendanceStatus.active;
        return ListTile(
          leading: Icon(
            isActive ? Icons.play_circle_outline : Icons.check_circle_outline,
            color: isActive ? AppColors.success : AppColors.textSecondary,
          ),
          title: Text(
            record.date,
            style: TextStyle(
              fontWeight: isActive ? FontWeight.w600 : FontWeight.normal,
            ),
          ),
          subtitle: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Entrada: ${_formatTime(record.checkInTime)}'
                '${record.checkOutTime != null ? '  |  Salida: ${_formatTime(record.checkOutTime!)}' : ''}'
                '${record.durationMinutes != null ? '  |  ${_formatDuration(record.durationMinutes!)}' : ''}',
                style: const TextStyle(fontSize: 13),
              ),
              if (record.workplaceId != null && !isActive)
                Text(
                  'Lugar: ${record.workplaceId}',
                  style: TextStyle(fontSize: 11, color: Colors.grey.shade500),
                ),
            ],
          ),
          isThreeLine: record.workplaceId != null && !isActive,
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
