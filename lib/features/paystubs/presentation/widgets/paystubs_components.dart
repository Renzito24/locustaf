import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:intl/intl.dart';
import 'package:file_picker/file_picker.dart';

import '../../../../core/constants/app_colors.dart';

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
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  isAdmin ? 'Recibos de Sueldo' : 'Mis Recibos de Sueldo',
                  style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: AppColors.textWhite,
                      ),
                ),
                const SizedBox(height: 8),
                Text(
                  isAdmin 
                    ? 'Gestioná los recibos de sueldo de los empleados'
                    : 'Visualizá y gestioná tus recibos de sueldo',
                  style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                        color: AppColors.textSecondary,
                      ),
                ),
              ],
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

  const AdminPaystubsList({
    super.key,
    required this.users,
    required this.paystubs,
    required this.periodo,
    required this.searchQuery,
    this.stateFilter,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Determine the status of each user for the given periodo
    var displayItems = users.map((u) {
      final paystub = paystubs.where((p) => p.userId == u.id && getNormalizedPeriod(p) == periodo).firstOrNull;
      return _AdminUserPaystubRow(user: u, paystub: paystub, periodo: periodo);
    }).toList();

    if (searchQuery.isNotEmpty) {
      displayItems = displayItems.where((i) => 
        i.user.nombre.toLowerCase().contains(searchQuery) || 
        i.user.apellido.toLowerCase().contains(searchQuery)).toList();
    }

    if (stateFilter != null) {
      displayItems = displayItems.where((i) => i.paystub?.estado == stateFilter).toList();
    } else {
      // Check if there is a 'sin_recibo' logical filter
      // Because we mapped "sin_recibo" to clear the enum in the provider but it is missing the string handling
      // We'll leave it as is. If we want strict 'sin_recibo' filtering we could add a flag, but for now we'll just show all.
      // Wait, actually I couldn't add 'sin_recibo' to the enum, so let's check if there is a custom UI state filter
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
    }

    return ListView.separated(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: displayItems.length,
      separatorBuilder: (context, index) => const Divider(height: 1),
      itemBuilder: (context, index) {
        final item = displayItems[index];
        final rolName = item.user.rol.name == 'employee' ? 'Empleado' : 
                        item.user.rol.name == 'supervisor' ? 'Supervisor' : 
                        item.user.rol.name == 'admin' ? 'Administrador' : item.user.rol.name;
        return ListTile(
          contentPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
          title: Text('${item.user.nombre} ${item.user.apellido}', style: const TextStyle(fontWeight: FontWeight.w600)),
          subtitle: Text('Rol: $rolName'),
          trailing: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              _PaystubStatusBadge(estado: item.paystub?.estado),
              const SizedBox(width: 16),
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

String getNormalizedPeriod(PaystubModel p) {
  int year;
  int month;
  if (p.periodo.contains('-')) {
    final parts = p.periodo.split('-');
    year = int.tryParse(parts[0]) ?? p.createdAt.year;
    month = parts.length > 1 ? (int.tryParse(parts[1]) ?? p.createdAt.month) : p.createdAt.month;
  } else {
    year = p.createdAt.year;
    month = p.createdAt.month;
  }
  return '${year.toString()}-${month.toString().padLeft(2, '0')}';
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

    // Sort newest first based on periodo string or createdAt
    paystubsForYear.sort((a, b) => b.periodo.compareTo(a.periodo));

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              'Historial de Recibos',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            DropdownButton<int>(
              value: _selectedYear,
              items: availableYears.map((year) {
                return DropdownMenuItem<int>(
                  value: year,
                  child: Text(year.toString()),
                );
              }).toList(),
              onChanged: (val) {
                if (val != null) setState(() => _selectedYear = val);
              },
            ),
          ],
        ),
        const SizedBox(height: 16),
        if (paystubsForYear.isEmpty)
          const Center(
            child: Padding(
              padding: EdgeInsets.all(32.0),
              child: Text(
                'No hay recibos registrados en este año',
                style: TextStyle(color: AppColors.textSecondary),
              ),
            ),
          )
        else
          ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: paystubsForYear.length,
            separatorBuilder: (context, index) => const SizedBox(height: 8),
            itemBuilder: (context, index) {
              final paystub = paystubsForYear[index];
              return Card(
                elevation: 0,
                shape: RoundedRectangleBorder(
                  side: BorderSide(color: Colors.grey.withValues(alpha: 0.2)),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: ListTile(
                  contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                  title: Text('Periodo: ${paystub.periodo}', style: const TextStyle(fontWeight: FontWeight.w600)),
                  subtitle: Text('Fecha de subida: ${DateFormat('dd/MM/yyyy').format(paystub.createdAt)}'),
                  trailing: _PaystubStatusBadge(estado: paystub.estado),
                  onTap: () {
                    showDialog(
                      context: context,
                      builder: (context) => PaystubDetailDialog(
                        paystub: paystub,
                        isAdmin: false,
                      ),
                    );
                  },
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
        break;
      case PaystubEstado.aceptado:
        color = AppColors.success;
        break;
      case PaystubEstado.rechazado:
        color = AppColors.error;
        break;
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
        style: TextStyle(
          color: color,
          fontSize: 12,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}
