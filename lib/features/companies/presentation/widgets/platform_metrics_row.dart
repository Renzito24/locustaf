import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/widgets/widgets.dart';
import '../providers/company_providers.dart';

/// Tarjetas resumen de la plataforma (TASK-011): total, activas, suspendidas,
/// próximas a vencer y en prueba.
class PlatformMetricsRow extends ConsumerWidget {
  const PlatformMetricsRow({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final metrics = ref.watch(platformMetricsProvider);
    final isMobile = AppTheme.isMobile(context);

    final cards = <_MetricCardData>[
      _MetricCardData(
        label: 'Total',
        value: metrics.total,
        icon: Icons.business_outlined,
        color: AppColors.gold,
      ),
      _MetricCardData(
        label: 'Activas',
        value: metrics.activas,
        icon: Icons.check_circle_outline,
        color: AppColors.success,
      ),
      _MetricCardData(
        label: 'Suspendidas',
        value: metrics.suspendidas,
        icon: Icons.block_outlined,
        color: AppColors.error,
      ),
      _MetricCardData(
        label: 'Próximas a vencer',
        value: metrics.porVencer,
        icon: Icons.event_outlined,
        color: AppColors.warning,
      ),
      _MetricCardData(
        label: 'En prueba',
        value: metrics.enPrueba,
        icon: Icons.science_outlined,
        color: AppColors.info,
      ),
    ];

    return Wrap(
      spacing: 12,
      runSpacing: 12,
      children: cards.asMap().entries.map((e) {
        final isLastAndOdd = e.key == cards.length - 1 && cards.length % 2 != 0;
        return _MetricCard(data: e.value, isMobile: isMobile, isLastAndOdd: isLastAndOdd);
      }).toList(),
    );
  }
}

class _MetricCardData {
  final String label;
  final int value;
  final IconData icon;
  final Color color;

  const _MetricCardData({
    required this.label,
    required this.value,
    required this.icon,
    required this.color,
  });
}

class _MetricCard extends StatelessWidget {
  final _MetricCardData data;
  final bool isMobile;
  final bool isLastAndOdd;

  const _MetricCard({
    required this.data,
    required this.isMobile,
    this.isLastAndOdd = false,
  });

  @override
  Widget build(BuildContext context) {
    double width;
    if (isMobile) {
      if (isLastAndOdd) {
        width = MediaQuery.sizeOf(context).width - 32;
      } else {
        width = (MediaQuery.sizeOf(context).width - 32) / 2 - 6;
      }
    } else {
      width = 200;
    }

    return SizedBox(
      width: width,
      child: AppCard(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: data.color.withValues(alpha: 0.15),
              ),
              child: Icon(data.icon, color: data.color, size: 20),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '${data.value}',
                    style: const TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.w700,
                      color: AppColors.textWhite,
                    ),
                  ),
                  Text(
                    data.label,
                    style: const TextStyle(
                      color: AppColors.textMuted,
                      fontSize: 12,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
