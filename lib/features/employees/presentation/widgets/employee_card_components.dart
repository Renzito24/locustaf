import 'package:flutter/material.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/models/user_model.dart';

class EmployeeAvatar extends StatelessWidget {
  final String initials;

  const EmployeeAvatar({super.key, required this.initials});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 48,
      height: 48,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: AppTheme.goldGradient,
      ),
      child: Center(
        child: Text(
          initials,
          style: const TextStyle(
            color: AppColors.textPrimary,
            fontSize: 16,
            fontWeight: FontWeight.bold,
            letterSpacing: 1,
          ),
        ),
      ),
    );
  }
}

class EmployeeDetails extends StatelessWidget {
  final UserModel employee;

  const EmployeeDetails({super.key, required this.employee});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          employee.nombreCompleto,
          style: const TextStyle(
            color: AppColors.textWhite,
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 6),
        Wrap(
          spacing: 16,
          runSpacing: 4,
          children: [
            EmployeeDetailItem(icon: Icons.email_outlined, text: employee.email),
            EmployeeDetailItem(icon: Icons.badge_outlined, text: 'DNI: ${employee.dni}'),
            if (employee.telefono != null && employee.telefono!.isNotEmpty)
              EmployeeDetailItem(icon: Icons.phone_outlined, text: employee.telefono!),
          ],
        ),
      ],
    );
  }
}

class EmployeeDetailItem extends StatelessWidget {
  final IconData icon;
  final String text;

  const EmployeeDetailItem({super.key, required this.icon, required this.text});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(
          icon,
          size: 14,
          color: AppColors.textMuted.withValues(alpha: 0.7),
        ),
        const SizedBox(width: 6),
        Text(
          text,
          style: TextStyle(
            color: AppColors.textMuted.withValues(alpha: 0.85),
            fontSize: 13,
          ),
        ),
      ],
    );
  }
}

class EmployeeActionsMenu extends StatelessWidget {
  final UserModel employee;
  final VoidCallback? onEdit;
  final VoidCallback? onToggleActive;
  final VoidCallback? onHistory;
  final VoidCallback? onDelete;
  final VoidCallback? onPasswordReset;

  const EmployeeActionsMenu({
    super.key,
    required this.employee,
    this.onEdit,
    this.onToggleActive,
    this.onHistory,
    this.onDelete,
    this.onPasswordReset,
  });

  @override
  Widget build(BuildContext context) {
    return PopupMenuButton<String>(
      icon: const Icon(
        Icons.more_vert,
        color: AppColors.textMuted,
      ),
      color: AppColors.cardDark,
      onSelected: (value) {
        switch (value) {
          case 'edit':
            onEdit?.call();
            break;
          case 'toggleActive':
            EmployeeDialogs.confirmToggleActive(context, employee, onToggleActive);
            break;
          case 'history':
            onHistory?.call();
            break;
          case 'passwordReset':
            EmployeeDialogs.confirmPasswordReset(context, employee, onPasswordReset);
            break;
          case 'delete':
            EmployeeDialogs.confirmDelete(context, onDelete);
            break;
        }
      },
      itemBuilder: (BuildContext context) {
        final items = <PopupMenuEntry<String>>[];
        if (onEdit != null) {
          items.add(
            PopupMenuItem<String>(
              value: 'edit',
              child: Row(
                children: const [
                  Icon(Icons.edit_outlined, size: 18, color: AppColors.textMuted),
                  SizedBox(width: 8),
                  Text('Editar', style: TextStyle(color: AppColors.textWhite)),
                ],
              ),
            ),
          );
        }
        if (onHistory != null) {
          items.add(
            PopupMenuItem<String>(
              value: 'history',
              child: Row(
                children: const [
                  Icon(Icons.history_outlined, size: 18, color: AppColors.textMuted),
                  SizedBox(width: 8),
                  Text('Historial', style: TextStyle(color: AppColors.textWhite)),
                ],
              ),
            ),
          );
        }
        if (onPasswordReset != null) {
          items.add(PopupMenuDivider(color: AppColors.gold.withValues(alpha: 0.2)));
          items.add(
            PopupMenuItem<String>(
              value: 'passwordReset',
              child: Row(
                children: const [
                  Icon(Icons.lock_reset_outlined, size: 18, color: AppColors.textMuted),
                  SizedBox(width: 8),
                  Expanded(
                    child: Text('Restablecer contraseña', style: TextStyle(color: AppColors.textWhite), overflow: TextOverflow.ellipsis,),
                  ),
                ],
              ),
            ),
          );
        }
        if (onToggleActive != null) {
          items.addAll([
            if (items.isNotEmpty) PopupMenuDivider(color: AppColors.gold.withValues(alpha: 0.2)),
            PopupMenuItem<String>(
              value: 'toggleActive',
              child: Row(
                children: [
                  Icon(
                    employee.isActive ? Icons.block_flipped : Icons.check_circle_outline,
                    size: 18,
                    color: employee.isActive ? AppColors.error : AppColors.success,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    employee.isActive ? 'Desactivar' : 'Activar',
                    style: TextStyle(
                      color: employee.isActive ? AppColors.error : AppColors.success,
                    ),
                  ),
                ],
              ),
            ),
          ]);
        }
        if (onDelete != null) {
          items.addAll([
            if (items.isNotEmpty) PopupMenuDivider(color: AppColors.gold.withValues(alpha: 0.2)),
            PopupMenuItem<String>(
              value: 'delete',
              child: Row(
                children: const [
                  Icon(
                    Icons.delete_outline,
                    size: 18,
                    color: AppColors.error,
                  ),
                  SizedBox(width: 8),
                  Text(
                    'Eliminar',
                    style: TextStyle(color: AppColors.error),
                  ),
                ],
              ),
            ),
          ]);
        }
        return items;
      },
    );
  }
}

class EmployeeDialogs {
  static Future<void> confirmToggleActive(BuildContext context, UserModel employee, VoidCallback? onToggleActive) async {
    final deactivating = employee.isActive;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.cardDark,
        title: Text(deactivating ? 'Desactivar usuario' : 'Activar usuario',
            style: const TextStyle(color: AppColors.textWhite)),
        content: Text(
          deactivating
              ? '${employee.nombreCompleto} no podrá iniciar sesión hasta que lo reactives. ¿Deseas continuar?'
              : '${employee.nombreCompleto} podrá volver a iniciar sesión. ¿Deseas continuar?',
          style: const TextStyle(color: AppColors.textMuted),
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppTheme.radiusXl),
          side: BorderSide(color: AppColors.gold.withValues(alpha: 0.18)),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Cancelar', style: TextStyle(color: AppColors.textMuted)),
          ),
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            style: TextButton.styleFrom(
                foregroundColor: deactivating ? AppColors.error : AppColors.success),
            child: Text(deactivating ? 'Desactivar' : 'Activar'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      onToggleActive?.call();
    }
  }

  static Future<void> confirmDelete(BuildContext context, VoidCallback? onDelete) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.cardDark,
        title: const Text('Eliminar usuario', style: TextStyle(color: AppColors.textWhite)),
        content: const Text(
          '¿Seguro que deseas eliminar este usuario?',
          style: TextStyle(color: AppColors.textMuted),
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppTheme.radiusXl),
          side: BorderSide(color: AppColors.gold.withValues(alpha: 0.18)),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Cancelar', style: TextStyle(color: AppColors.textMuted)),
          ),
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            style: TextButton.styleFrom(foregroundColor: AppColors.error),
            child: const Text('Eliminar'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      onDelete?.call();
    }
  }

  static Future<void> confirmPasswordReset(BuildContext context, UserModel employee, VoidCallback? onPasswordReset) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.cardDark,
        title: const Text('Restablecer contraseña', style: TextStyle(color: AppColors.textWhite)),
        content: Text(
          'Se enviará un correo de restablecimiento a ${employee.email}. ¿Desea continuar?',
          style: const TextStyle(color: AppColors.textMuted),
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppTheme.radiusXl),
          side: BorderSide(color: AppColors.gold.withValues(alpha: 0.18)),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Cancelar', style: TextStyle(color: AppColors.textMuted)),
          ),
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            style: TextButton.styleFrom(foregroundColor: AppColors.gold),
            child: const Text('Enviar'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      onPasswordReset?.call();
    }
  }
}
