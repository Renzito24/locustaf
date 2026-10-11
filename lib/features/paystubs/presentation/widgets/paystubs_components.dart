import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:intl/intl.dart';
import 'package:file_picker/file_picker.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/providers/async_action_state.dart';
import '../../../../core/theme/app_theme.dart';

import '../../../../core/models/user_model.dart';
import '../../domain/models/paystub_model.dart';
import '../providers/paystubs_provider.dart';

import 'paystub_detail_dialog.dart';

class PaystubsHeader extends ConsumerWidget {
  final bool isAdmin;
  
  const PaystubsHeader({
    super.key,
    required this.isAdmin,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: AppColors.gold.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(LucideIcons.fileText, color: AppColors.gold, size: 24),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    isAdmin ? 'Recibos de Sueldo' : 'Mis Recibos de Sueldo',
                    style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: AppColors.textWhite,
                        ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    isAdmin
                        ? 'Gestioná los recibos de sueldo de los empleados'
                        : 'Visualizá y gestioná tus recibos de sueldo',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: AppColors.textSecondary,
                        ),
                    softWrap: true,
                  ),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 32),
      ],
    );
  }
}

class AdminPaystubsList extends ConsumerWidget {
  final List<UserModel> users;
  final List<PaystubModel> paystubs;
  final String periodo;
  final String searchQuery;
  final PaystubEstado? stateFilter;
  final bool sinRecibo;

  const AdminPaystubsList({
    super.key,
    required this.users,
    required this.paystubs,
    required this.periodo,
    required this.searchQuery,
    this.stateFilter,
    this.sinRecibo = false,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    ref.listen<PaystubActionState>(paystubCreateProvider, (prev, next) {
      if (prev?.status != AsyncActionStatus.loading) return;
      if (next.status == AsyncActionStatus.success) {
        ref.read(paystubCreateProvider.notifier).reset();
        ScaffoldMessenger.of(context).showSnackBar(
          AppTheme.successSnackBar('Recibo subido correctamente'),
        );
      } else if (next.status == AsyncActionStatus.failure) {
        ScaffoldMessenger.of(context).showSnackBar(
          AppTheme.errorSnackBar('Error al subir el recibo: ${next.error}'),
        );
      }
    });

    ref.listen<AsyncActionState>(paystubDeleteProvider, (prev, next) {
      if (prev?.status != AsyncActionStatus.loading) return;
      if (next.status == AsyncActionStatus.success) {
        ref.read(paystubDeleteProvider.notifier).reset();
        ScaffoldMessenger.of(context).showSnackBar(
          AppTheme.successSnackBar('Recibo eliminado correctamente'),
        );
      } else if (next.status == AsyncActionStatus.failure) {
        ScaffoldMessenger.of(context).showSnackBar(
          AppTheme.errorSnackBar('Error al eliminar el recibo: ${next.error}'),
        );
      }
    });

    // Determine the status of each user for the given periodo
    var displayItems = users.map((u) {
      final paystub = paystubs.where((p) => p.userId == u.id && p.normalizedPeriod == periodo).firstOrNull;
      return _AdminUserPaystubRow(user: u, paystub: paystub, periodo: periodo);
    }).toList();

    if (searchQuery.isNotEmpty) {
      displayItems = displayItems.where((i) => 
        i.user.nombre.toLowerCase().contains(searchQuery) || 
        i.user.apellido.toLowerCase().contains(searchQuery)).toList();
    }

    if (sinRecibo) {
      displayItems = displayItems.where((i) => i.paystub == null).toList();
    } else if (stateFilter != null) {
      displayItems = displayItems.where((i) => i.paystub?.estado == stateFilter).toList();
    }

    if (displayItems.isEmpty) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(32.0),
          child: Text(
            'No hay empleados para mostrar',
            style: TextStyle(color: AppColors.textSecondary),
          ),
        ),
      );
    }    return ListView.separated(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: displayItems.length,
      separatorBuilder: (_, i) => const SizedBox(height: 8),
      itemBuilder: (context, index) {
        final item = displayItems[index];
        final rolName = item.user.rol.label;

        final Color borderColor;
        if (item.paystub == null) {
          borderColor = Colors.grey.shade500;
        } else {
          switch (item.paystub!.estado) {
            case PaystubEstado.pendiente:
              borderColor = AppColors.warning;
            case PaystubEstado.aceptado:
              borderColor = AppColors.success;
            case PaystubEstado.rechazado:
              borderColor = AppColors.error;
          }
        }

        final initials =
            '${item.user.nombre.isNotEmpty ? item.user.nombre[0] : '?'}'
            '${item.user.apellido.isNotEmpty ? item.user.apellido[0] : ''}';

        return Material(
          color: AppColors.bgDarkTop,
          borderRadius: BorderRadius.circular(12),
          clipBehavior: Clip.antiAlias,
          child: Container(
            decoration: BoxDecoration(
              border: Border(
                left: BorderSide(color: borderColor, width: 4),
                top: BorderSide(color: borderColor.withValues(alpha: 0.2)),
                right: BorderSide(color: borderColor.withValues(alpha: 0.2)),
                bottom: BorderSide(color: borderColor.withValues(alpha: 0.2)),
              ),
            ),
            child: ListTile(
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
            leading: CircleAvatar(
              backgroundColor: borderColor.withValues(alpha: 0.2),
              child: Text(
                initials.toUpperCase(),
                style: TextStyle(
                  color: borderColor,
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                ),
              ),
            ),
            title: Text(
              '${item.user.nombre} ${item.user.apellido}',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                fontWeight: FontWeight.w600,
                color: AppColors.textWhite,
              ),
            ),
            subtitle: Row(
              children: [
                Flexible(
                  child: Text(
                    rolName,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(color: AppColors.textMuted, fontSize: 12),
                  ),
                ),
                const SizedBox(width: 8),
                Flexible(
                  fit: FlexFit.loose,
                  child: _PaystubStatusBadge(estado: item.paystub?.estado),
                ),
              ],
            ),
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (item.paystub == null)
                  IconButton(
                    icon: const Icon(LucideIcons.upload, color: AppColors.gold),
                    tooltip: 'Subir recibo',
                    onPressed: () => _uploadPaystub(context, ref, item.user, periodo),
                  )
                else ...[
                  IconButton(
                    icon: const Icon(LucideIcons.fileText, color: AppColors.gold),
                    tooltip: 'Ver recibo',
                    onPressed: () => _showPaystubDetails(context, item.paystub!, item.user),
                  ),
                  IconButton(
                    icon: const Icon(LucideIcons.trash2, color: AppColors.error),
                    tooltip: 'Eliminar',
                    onPressed: () => _deletePaystub(context, ref, item.paystub!),
                  ),
                ],
              ],
            ),
            ),
          ),
        );
      },
    );
  }

  Future<void> _uploadPaystub(BuildContext context, WidgetRef ref, UserModel user, String periodo) async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['pdf'],
    );
    if (result != null && result.files.isNotEmpty) {
      final file = result.files.first;
      if (file.size > 10 * 1024 * 1024) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('El archivo no debe pesar más de 10 MB')));
        }
        return;
      }

      await ref.read(paystubCreateProvider.notifier).createPaystub(
        userId: user.id,
        periodo: periodo,
        file: file,
      );
    }
  }

  void _showPaystubDetails(BuildContext context, PaystubModel paystub, UserModel user) {
    showDialog(
      context: context,
      builder: (context) => PaystubDetailDialog(
        paystub: paystub,
        user: user,
        isAdmin: true,
      ),
    );
  }

  void _deletePaystub(BuildContext context, WidgetRef ref, PaystubModel paystub) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Eliminar recibo', style: TextStyle(color: AppColors.error)),
        content: const Text(
          '¿Estás seguro de que querés eliminar este recibo? \n\n'
          '⚠️ Se borrará el archivo y se perderá la respuesta del empleado.',
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancelar')),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              ref.read(paystubDeleteProvider.notifier).deletePaystub(paystub);
            },
            child: const Text('Eliminar', style: TextStyle(color: AppColors.error)),
          ),
        ],
      ),
    );
  }
}

class _AdminUserPaystubRow {
  final UserModel user;
  final PaystubModel? paystub;
  final String periodo;

  _AdminUserPaystubRow({required this.user, this.paystub, required this.periodo});
}

class EmployeePaystubsList extends ConsumerStatefulWidget {
  final List<PaystubModel> paystubs;

  const EmployeePaystubsList({
    super.key,
    required this.paystubs,
  });

  @override
  ConsumerState<EmployeePaystubsList> createState() => _EmployeePaystubsListState();
}

class _EmployeePaystubsListState extends ConsumerState<EmployeePaystubsList> {
  int? _selectedYear;

  List<int> _getAvailableYears() {
    final years = <int>{DateTime.now().year};
    for (final p in widget.paystubs) {
      final y = int.tryParse(p.periodo.split('-').first) ?? p.createdAt.year;
      years.add(y);
    }
    final sorted = years.toList()..sort((a, b) => b.compareTo(a));
    return sorted;
  }

  @override
  Widget build(BuildContext context) {
    final availableYears = _getAvailableYears();
    _selectedYear ??= availableYears.first;

    if (!availableYears.contains(_selectedYear)) {
      _selectedYear = availableYears.isNotEmpty ? availableYears.first : DateTime.now().year;
    }

    final paystubsForYear = widget.paystubs.where((p) {
      final y = int.tryParse(p.periodo.split('-').first) ?? p.createdAt.year;
      return y == _selectedYear;
    }).toList();

    paystubsForYear.sort((a, b) => b.periodo.compareTo(a.periodo));

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Historial de Recibos',
          style: TextStyle(
            fontSize: 17,
            fontWeight: FontWeight.bold,
            color: AppColors.textWhite,
          ),
        ),
        const SizedBox(height: 12),
        // Selector de año como chips
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: availableYears.map((year) {
              final selected = year == _selectedYear;
              return Padding(
                padding: const EdgeInsets.only(right: 8),
                child: ChoiceChip(
                  label: Text(year.toString()),
                  selected: selected,
                  onSelected: (_) => setState(() => _selectedYear = year),
                  selectedColor: AppColors.gold,
                  backgroundColor: AppColors.bgDarkTop,
                  labelStyle: TextStyle(
                    color: selected ? AppColors.bgDarkTop : AppColors.textMuted,
                    fontWeight: FontWeight.w600,
                  ),
                  side: BorderSide(
                    color: selected
                        ? AppColors.gold
                        : AppColors.textSecondary.withValues(alpha: 0.35),
                  ),
                  showCheckmark: false,
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                ),
              );
            }).toList(),
          ),
        ),
        const SizedBox(height: 20),
        if (paystubsForYear.isEmpty)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 32),
            child: Center(
              child: Column(
                children: [
                  Icon(LucideIcons.inbox, size: 48, color: AppColors.textSecondary),
                  const SizedBox(height: 16),
                  const Text(
                    'Sin recibos este año',
                    style: TextStyle(
                      color: AppColors.textSecondary,
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 6),
                  const Text(
                    'Los recibos subidos por tu empresa aparecerán aquí.',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: AppColors.textMuted, fontSize: 13),
                  ),
                ],
              ),
            ),
          )
        else
          ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: paystubsForYear.length,
            separatorBuilder: (_, i) => const SizedBox(height: 8),
            itemBuilder: (context, index) {
              final paystub = paystubsForYear[index];
              return _EmployeePaystubCard(
                paystub: paystub,
                onTap: () => showDialog(
                  context: context,
                  builder: (context) => PaystubDetailDialog(
                    paystub: paystub,
                    isAdmin: false,
                  ),
                ),
              );
            },
          ),
      ],
    );
  }
}

class _PaystubStatusBadge extends StatelessWidget {
  final PaystubEstado? estado;

  const _PaystubStatusBadge({required this.estado});

  @override
  Widget build(BuildContext context) {
    if (estado == null) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: Colors.grey.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.grey.withValues(alpha: 0.2)),
        ),
        child: const Text(
          'Sin recibo',
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(
            color: Colors.grey,
            fontSize: 12,
            fontWeight: FontWeight.w600,
          ),
        ),
      );
    }

    Color color;
    switch (estado!) {
      case PaystubEstado.pendiente:
        color = AppColors.warning;
      case PaystubEstado.aceptado:
        color = AppColors.success;
      case PaystubEstado.rechazado:
        color = AppColors.error;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withValues(alpha: 0.2)),
      ),
      child: Text(
        estado!.displayName,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: TextStyle(
          color: color,
          fontSize: 12,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}

class _EmployeePaystubCard extends StatelessWidget {
  final PaystubModel paystub;
  final VoidCallback onTap;

  const _EmployeePaystubCard({required this.paystub, required this.onTap});

  static const _meses = [
    '', 'Enero', 'Febrero', 'Marzo', 'Abril', 'Mayo', 'Junio',
    'Julio', 'Agosto', 'Septiembre', 'Octubre', 'Noviembre', 'Diciembre',
  ];

  String get _formattedPeriodo {
    try {
      final parts = paystub.periodo.split('-');
      if (parts.length >= 2) {
        final year = int.parse(parts[0]);
        final month = int.parse(parts[1]);
        if (month >= 1 && month <= 12) return '${_meses[month]} $year';
      }
    } catch (_) {}
    return paystub.periodo;
  }

  @override
  Widget build(BuildContext context) {
    Color statusColor;
    IconData statusIcon;

    switch (paystub.estado) {
      case PaystubEstado.pendiente:
        statusColor = AppColors.warning;
        statusIcon = LucideIcons.clock;
      case PaystubEstado.aceptado:
        statusColor = AppColors.success;
        statusIcon = LucideIcons.circleCheck;
      case PaystubEstado.rechazado:
        statusColor = AppColors.error;
        statusIcon = LucideIcons.circleX;
    }

    return Material(
      color: AppColors.bgDarkTop,
      borderRadius: BorderRadius.circular(12),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: statusColor.withValues(alpha: 0.35)),
          ),
          child: Row(
          children: [
            Container(
              width: 46,
              height: 46,
              decoration: BoxDecoration(
                color: statusColor.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(statusIcon, color: statusColor, size: 22),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    _formattedPeriodo,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: AppColors.textWhite,
                      fontWeight: FontWeight.w600,
                      fontSize: 15,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    'Subido el ${DateFormat('dd/MM/yyyy').format(paystub.createdAt)}',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(color: AppColors.textMuted, fontSize: 12),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            Flexible(
              fit: FlexFit.loose,
              child: _PaystubStatusBadge(estado: paystub.estado),
            ),
            const SizedBox(width: 4),
            const Icon(Icons.chevron_right, color: AppColors.textSecondary, size: 20),
            ],
          ),
        ),
      ),
    );
  }
}

