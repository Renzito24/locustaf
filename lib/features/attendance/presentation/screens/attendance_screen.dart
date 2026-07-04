import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../authentication/presentation/providers/auth_provider.dart';
import '../../data/models/attendance_model.dart';
import '../providers/attendance_notifier.dart';

class AttendanceScreen extends ConsumerWidget {
  const AttendanceScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authUser = ref.watch(currentUserProvider);
    final userId = authUser?.uid;

    if (userId == null) {
      return const Center(child: Text('Usuario no autenticado'));
    }

    final activeAttendanceAsync = ref.watch(activeAttendanceProvider(userId));
    final attendancesAsync = ref.watch(attendancesByUserProvider(userId));

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
            ),
          ),
          const SizedBox(height: 24),
          activeAttendanceAsync.when(
            data: (active) => _buildActiveSection(context, ref, active),
            loading: () => const CircularProgressIndicator(),
            error: (e, _) => Text('Error: $e'),
          ),
          const SizedBox(height: 24),
          const Text(
            'Historial',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 12),
          Expanded(
            child: attendancesAsync.when(
              data: (list) => _buildHistoryList(list),
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (e, _) => Center(child: Text('Error: $e')),
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
  ) {
    final authUser = ref.watch(currentUserProvider);
    final userId = authUser?.uid ?? '';

    if (active == null) {
      return Center(
        child: ElevatedButton.icon(
          onPressed: () {
            ref.read(attendanceActionProvider.notifier).checkIn(userId);
          },
          icon: const Icon(Icons.login),
          label: const Text('Iniciar jornada'),
          style: ElevatedButton.styleFrom(
            padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
            textStyle: const TextStyle(fontSize: 16),
          ),
        ),
      );
    }

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.access_time, color: Colors.green),
                const SizedBox(width: 8),
                Text(
                  'Jornada activa',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                    color: Colors.green.shade700,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text('Inicio: ${_formatDateTime(active.checkInTime)}'),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: () {
                  ref.read(attendanceActionProvider.notifier).checkOut(active.uid);
                },
                icon: const Icon(Icons.logout),
                label: const Text('Finalizar jornada'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.orange,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  textStyle: const TextStyle(fontSize: 16),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHistoryList(List<AttendanceModel> list) {
    if (list.isEmpty) {
      return const Center(
        child: Text(
          'Sin registros de asistencia',
          style: TextStyle(color: Colors.grey),
        ),
      );
    }

    return ListView.separated(
      itemCount: list.length,
      separatorBuilder: (_, _) => const Divider(height: 1),
      itemBuilder: (context, index) {
        final record = list[index];
        return ListTile(
          leading: Icon(
            record.status == AttendanceStatus.active
                ? Icons.play_circle_outline
                : Icons.check_circle_outline,
            color: record.status == AttendanceStatus.active
                ? Colors.green
                : Colors.grey,
          ),
          title: Text(record.date),
          subtitle: Text(
            'Entrada: ${_formatTime(record.checkInTime)}'
            '${record.checkOutTime != null ? '  |  Salida: ${_formatTime(record.checkOutTime!)}' : ''}'
            '${record.durationMinutes != null ? '  |  Duración: ${record.durationMinutes}min' : ''}',
          ),
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
}
