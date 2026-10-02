import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'dart:ui';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/widgets/widgets.dart';
import '../../../workplaces/presentation/providers/workplace_notifier.dart';
import '../../data/models/attendance_model.dart';
import '../providers/attendance_notifier.dart';

class ActiveAttendanceCard extends ConsumerWidget {
  final AttendanceModel? active;
  final String userId;
  final bool isActionLoading;

  const ActiveAttendanceCard({
    super.key,
    required this.active,
    required this.userId,
    required this.isActionLoading,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (active == null) {
      return AppCard(
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
      final found = list.where((w) => w.id == active!.workplaceId).toList();
      if (found.isNotEmpty) {
        workplaceName = found.first.nombre;
      }
    });

    return AppCard(
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
          _kvRow('Inicio', _formatDateTime(active!.checkInTime)),
          if (workplaceName != null) ...[
            Divider(
              height: 24,
              color: AppColors.gold.withValues(alpha: 0.1),
            ),
            _kvRow('Lugar', workplaceName!),
          ],
          const SizedBox(height: 20),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: isActionLoading
                  ? null
                  : () {
                      ref.read(attendanceActionProvider.notifier).checkOut(active!.id, userId);
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

  Widget _kvRow(String key, String value) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(key, style: AppTheme.bodyMd),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            value,
            textAlign: TextAlign.right,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              fontWeight: FontWeight.w500,
              color: AppColors.textWhite,
              fontFeatures: [FontFeature.tabularFigures()],
            ),
          ),
        ),
      ],
    );
  }

  String _formatDateTime(DateTime dt) {
    return '${dt.day}/${dt.month}/${dt.year} ${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';
  }
}
