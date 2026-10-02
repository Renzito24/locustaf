import 'package:flutter/material.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/widgets/widgets.dart';

class EmployeeReportsFilterBar extends StatelessWidget {
  final int selectedMonth;
  final int selectedYear;
  final ValueChanged<int?> onMonthChanged;
  final ValueChanged<int?> onYearChanged;

  const EmployeeReportsFilterBar({
    super.key,
    required this.selectedMonth,
    required this.selectedYear,
    required this.onMonthChanged,
    required this.onYearChanged,
  });

  @override
  Widget build(BuildContext context) {
    const months = [
      'Enero', 'Febrero', 'Marzo', 'Abril', 'Mayo', 'Junio',
      'Julio', 'Agosto', 'Septiembre', 'Octubre', 'Noviembre', 'Diciembre',
    ];

    return AppCard(
      padding: const EdgeInsets.all(16),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final monthField = SizedBox(
            width: double.infinity,
            child: DropdownButtonFormField<int>(
              initialValue: selectedMonth,
              isExpanded: true,
              decoration: AppTheme.inputDecoration(label: 'Mes', icon: Icons.calendar_today),
              dropdownColor: AppColors.cardDark,
              style: const TextStyle(color: AppColors.textWhite),
              items: List.generate(12, (i) => DropdownMenuItem(
                value: i + 1,
                child: Text(months[i]),
              )),
              onChanged: onMonthChanged,
            ),
          );
          final yearField = SizedBox(
            width: double.infinity,
            child: DropdownButtonFormField<int>(
              initialValue: selectedYear,
              isExpanded: true,
              decoration: AppTheme.inputDecoration(label: 'Año', icon: Icons.date_range),
              dropdownColor: AppColors.cardDark,
              style: const TextStyle(color: AppColors.textWhite),
              items: List.generate(5, (i) {
                final year = DateTime.now().year - i;
                return DropdownMenuItem(value: year, child: Text('$year'));
              }),
              onChanged: onYearChanged,
            ),
          );

          final isNarrow = constraints.maxWidth < 500;
          if (isNarrow) {
            return Column(
              children: [
                monthField,
                const SizedBox(height: 12),
                yearField,
              ],
            );
          }
          return Row(
            children: [
              SizedBox(width: 200, child: monthField),
              const SizedBox(width: 16),
              SizedBox(width: 140, child: yearField),
            ],
          );
        },
      ),
    );
  }
}

class EmployeeReportsExportSection extends StatelessWidget {
  final int selectedMonth;
  final int selectedYear;
  final int rowsCount;
  final bool workplacesReady;
  final VoidCallback onExportExcel;
  final VoidCallback onExportPdf;

  const EmployeeReportsExportSection({
    super.key,
    required this.selectedMonth,
    required this.selectedYear,
    required this.rowsCount,
    required this.workplacesReady,
    required this.onExportExcel,
    required this.onExportPdf,
  });

  String _monthName(int month) {
    const months = [
      'enero', 'febrero', 'marzo', 'abril', 'mayo', 'junio',
      'julio', 'agosto', 'septiembre', 'octubre', 'noviembre', 'diciembre',
    ];
    return months[month - 1];
  }

  @override
  Widget build(BuildContext context) {
    final monthName = _monthName(selectedMonth);
    final canExport = rowsCount > 0 && workplacesReady;

    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Reporte de asistencia de $monthName de $selectedYear',
            style: AppTheme.headingMd,
          ),
          const SizedBox(height: 4),
          if (rowsCount == 0)
            Text(
              'Sin registros para el período seleccionado.',
              style: AppTheme.bodyMd,
            )
          else
            Row(
              children: [
                Text(
                  '$rowsCount',
                  style: const TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: AppColors.goldLight,
                  ),
                ),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    'jornada(s) completadas.',
                    style: AppTheme.bodyMd,
                  ),
                ),
              ],
            ),
          if (rowsCount == 0) ...[
            const SizedBox(height: 12),
            Text(
              'No se pueden exportar reportes si no hay asistencias completadas.',
              style: AppTheme.bodyMd.copyWith(color: AppColors.warning),
            ),
          ] else if (!workplacesReady) ...[
            const SizedBox(height: 12),
            Row(
              children: [
                const SizedBox(
                  width: 12,
                  height: 12,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: AppColors.gold,
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Cargando lugares de trabajo... La exportación se habilita al terminar.',
                    style: AppTheme.bodyMd.copyWith(color: AppColors.textMuted),
                  ),
                ),
              ],
            ),
          ],
          const SizedBox(height: 16),
          LayoutBuilder(
            builder: (context, constraints) {
              final isNarrow = constraints.maxWidth < 480;
              final excelButton = OutlinedButton.icon(
                onPressed: canExport ? onExportExcel : null,
                icon: const Icon(Icons.grid_on, size: 18),
                label: const Text('Excel'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppColors.gold,
                  side: const BorderSide(color: AppColors.gold),
                ),
              );
              final pdfButton = OutlinedButton.icon(
                onPressed: canExport ? onExportPdf : null,
                icon: const Icon(Icons.picture_as_pdf, size: 18),
                label: const Text('PDF'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppColors.gold,
                  side: const BorderSide(color: AppColors.gold),
                ),
              );

              if (isNarrow) {
                return Row(
                  children: [
                    Expanded(child: excelButton),
                    const SizedBox(width: 8),
                    Expanded(child: pdfButton),
                  ],
                );
              }
              return Row(
                children: [
                  excelButton,
                  const SizedBox(width: 8),
                  pdfButton,
                ],
              );
            },
          ),
        ],
      ),
    );
  }
}
