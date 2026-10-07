import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:intl/intl.dart';

import '../../../../core/constants/app_colors.dart';

import '../../../../core/models/user_model.dart';
import '../../../../core/router/app_routes.dart';
import '../../domain/models/paystub_model.dart';

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
            if (isAdmin)
              ElevatedButton.icon(
                onPressed: () {
                  context.push(RoutePaths.createPaystub);
                },
                icon: const Icon(LucideIcons.upload),
                label: const Text('Subir Recibo'),
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                  backgroundColor: AppColors.gold,
                  foregroundColor: Colors.white,
                ),
              ),
          ],
        ),
        const SizedBox(height: 32),
      ],
    );
  }
}

class PaystubsList extends StatelessWidget {
  final List<PaystubModel> paystubs;
  final AsyncValue<List<UserModel>> usersAsync;
  final bool isAdmin;

  const PaystubsList({
    super.key,
    required this.paystubs,
    required this.usersAsync,
    required this.isAdmin,
  });

  @override
  Widget build(BuildContext context) {
    if (paystubs.isEmpty) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(32.0),
          child: Text(
            'No hay recibos de sueldo registrados',
            style: TextStyle(color: AppColors.textSecondary),
          ),
        ),
      );
    }

    return ListView.separated(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: paystubs.length,
      separatorBuilder: (context, index) => const Divider(height: 1),
      itemBuilder: (context, index) {
        final paystub = paystubs[index];
        final user = usersAsync.value?.firstWhere(
          (u) => u.id == paystub.userId,
          orElse: () => UserModel(
            id: '', companyId: '', email: '', nombre: 'Usuario', apellido: 'Desconocido', 
            dni: '', rol: UserRole.employee,
            createdAt: DateTime.now(), updatedAt: DateTime.now()
          ),
        );

        return ListTile(
          contentPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
          title: Text(
            isAdmin ? '${user?.nombre} ${user?.apellido}' : paystub.periodo,
            style: const TextStyle(fontWeight: FontWeight.w600),
          ),
          subtitle: Text(
            isAdmin ? 'Periodo: ${paystub.periodo}' : 'Fecha de subida: ${DateFormat('dd/MM/yyyy').format(paystub.createdAt)}',
          ),
          trailing: _PaystubStatusBadge(estado: paystub.estado),
          onTap: () {
            showDialog(
              context: context,
              builder: (context) => PaystubDetailDialog(
                paystub: paystub,
                user: user,
                isAdmin: isAdmin,
              ),
            );
          },
        );
      },
    );
  }
}

class _PaystubStatusBadge extends StatelessWidget {
  final PaystubEstado estado;

  const _PaystubStatusBadge({required this.estado});

  @override
  Widget build(BuildContext context) {
    Color color;
    switch (estado) {
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
        estado.displayName,
        style: TextStyle(
          color: color,
          fontSize: 12,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}
