import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/providers/data_providers.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../authentication/presentation/providers/auth_provider.dart';
import '../providers/attendance_notifier.dart';
import 'widgets/active_attendance_card.dart';
import 'widgets/admin_attendance_view.dart';
import 'widgets/orphaned_attendance_card.dart';

class AttendanceScreen extends ConsumerStatefulWidget {
  const AttendanceScreen({super.key});

  @override
  ConsumerState<AttendanceScreen> createState() => _AttendanceScreenState();
}

class _AttendanceScreenState extends ConsumerState<AttendanceScreen> {
  final Set<String> _dismissedOrphanedIds = {};

  @override
  Widget build(BuildContext context) {
    final userId = ref.watch(currentUserIdProvider);

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
      return const AdminAttendanceView();
    }

    final activeAttendanceAsync = ref.watch(activeAttendanceProvider(userId));
    final orphaned = ref.watch(orphanedAttendanceForUserProvider(userId));
    final isActionLoading = actionState.status == AttendanceActionStatus.loading;

    return SingleChildScrollView(
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
          if (orphaned != null &&
              !_dismissedOrphanedIds.contains(orphaned.id)) ...[
            OrphanedAttendanceCard(
              orphaned: orphaned,
              userId: userId,
              isActionLoading: isActionLoading,
              onDismiss: () {
                setState(() => _dismissedOrphanedIds.add(orphaned.id));
              },
            ),
            const SizedBox(height: 16),
          ],
          activeAttendanceAsync.when(
            data: (active) => ActiveAttendanceCard(
              active: active,
              userId: userId,
              isActionLoading: isActionLoading,
            ),
            loading: () => AppTheme.loadingState(message: 'Cargando asistencia...'),
            error: (e, _) => AppTheme.errorState(
              'Error al cargar: $e',
              onRetry: () {
                ref.invalidate(activeAttendanceProvider(userId));
                ref.invalidate(attendancesByUserProvider(userId));
              },
            ),
          ),
        ],
      ),
    );
  }
}
