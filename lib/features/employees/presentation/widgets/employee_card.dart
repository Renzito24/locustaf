import 'package:flutter/material.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../authentication/data/models/user_model.dart';

class EmployeeCard extends StatefulWidget {
  final UserModel employee;
  final VoidCallback? onEdit;
  final VoidCallback? onToggleActive;
  final VoidCallback? onHistory;
  final VoidCallback? onDelete;
  final VoidCallback? onPasswordReset;

  const EmployeeCard({
    super.key,
    required this.employee,
    this.onEdit,
    this.onToggleActive,
    this.onHistory,
    this.onDelete,
    this.onPasswordReset,
  });

  @override
  State<EmployeeCard> createState() => _EmployeeCardState();
}

class _EmployeeCardState extends State<EmployeeCard> {
  bool _isHovered = false;

  String get _initials {
    final name = widget.employee.nombre.trim();
    final lastName = widget.employee.apellido.trim();
    final firstChar = name.isNotEmpty ? name[0] : '';
    final secondChar = lastName.isNotEmpty ? lastName[0] : '';
    return '$firstChar$secondChar'.toUpperCase();
  }

  @override
  Widget build(BuildContext context) {
    final employee = widget.employee;

    return MouseRegion(
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: _isHovered ? AppColors.primary.withValues(alpha: 0.5) : Colors.grey.shade200,
            width: 1,
          ),
          boxShadow: [
            BoxShadow(
              color: _isHovered ? Colors.black.withValues(alpha: 0.08) : Colors.black.withValues(alpha: 0.03),
              blurRadius: _isHovered ? 12 : 6,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              // Avatar with Initials and subtle gradient
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: LinearGradient(
                    colors: [
                      AppColors.primary.withValues(alpha: 0.8),
                      AppColors.info.withValues(alpha: 0.8),
                    ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                ),
                child: Center(
                  child: Text(
                    _initials,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 1,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 16),

              // Main Details
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      employee.nombreCompleto,
                      style: const TextStyle(
                        color: AppColors.textPrimary,
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Wrap(
                      spacing: 16,
                      runSpacing: 4,
                      children: [
                        _buildDetailItem(Icons.email_outlined, employee.email),
                        _buildDetailItem(Icons.badge_outlined, 'DNI: ${employee.dni}'),
                        if (employee.telefono != null && employee.telefono!.isNotEmpty)
                          _buildDetailItem(Icons.phone_outlined, employee.telefono!),
                      ],
                    ),
                  ],
                ),
              ),

              const SizedBox(width: 16),

              // Status Badge
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: employee.isActive
                      ? AppColors.success.withValues(alpha: 0.1)
                      : AppColors.error.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  employee.isActive ? 'Activo' : 'Inactivo',
                  style: TextStyle(
                    color: employee.isActive ? AppColors.success : AppColors.error,
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),

              const SizedBox(width: 8),

              // Role Badge
              if (employee.rol == UserRole.supervisor)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: AppColors.warning.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    employee.rol.label,
                    style: const TextStyle(
                      color: AppColors.warning,
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              if (employee.rol == UserRole.supervisor) const SizedBox(width: 8),

              // Actions Menu
              PopupMenuButton<String>(
                icon: const Icon(
                  Icons.more_vert,
                  color: AppColors.textSecondary,
                ),
                onSelected: (value) {
                  switch (value) {
                    case 'edit':
                      widget.onEdit?.call();
                      break;
                    case 'toggleActive':
                      widget.onToggleActive?.call();
                      break;
                    case 'history':
                      widget.onHistory?.call();
                      break;
                    case 'passwordReset':
                      _confirmPasswordReset(context);
                      break;
                    case 'delete':
                      _confirmDelete(context);
                      break;
                  }
                },
                itemBuilder: (BuildContext context) {
                  final items = <PopupMenuEntry<String>>[];
                  if (widget.onEdit != null) {
                    items.add(
                      PopupMenuItem<String>(
                        value: 'edit',
                        child: const Row(
                          children: [
                            Icon(Icons.edit_outlined, size: 18),
                            SizedBox(width: 8),
                            Text('Editar'),
                          ],
                        ),
                      ),
                    );
                  }
                  if (widget.onHistory != null) {
                    items.add(
                      PopupMenuItem<String>(
                        value: 'history',
                        child: const Row(
                          children: [
                            Icon(Icons.history_outlined, size: 18),
                            SizedBox(width: 8),
                            Text('Historial'),
                          ],
                        ),
                      ),
                    );
                  }
                  if (widget.onPasswordReset != null) {
                    items.add(const PopupMenuDivider());
                    items.add(
                      PopupMenuItem<String>(
                        value: 'passwordReset',
                        child: const Row(
                          children: [
                            Icon(Icons.lock_reset_outlined, size: 18),
                            SizedBox(width: 8),
                            Text('Restablecer contraseña'),
                          ],
                        ),
                      ),
                    );
                  }
                  if (widget.onToggleActive != null) {
                    items.addAll([
                      if (items.isNotEmpty) const PopupMenuDivider(),
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
                  if (widget.onDelete != null) {
                    items.addAll([
                      if (items.isNotEmpty) const PopupMenuDivider(),
                      PopupMenuItem<String>(
                        value: 'delete',
                        child: const Row(
                          children: [
                            Icon(
                              Icons.delete_outline,
                              size: 18,
                              color: AppColors.error,
                            ),
                            SizedBox(width: 8),
                            Text(
                              'Eliminar',
                              style: TextStyle(
                                color: AppColors.error,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ]);
                  }
                  return items;
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _confirmDelete(BuildContext context) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Eliminar usuario'),
        content: const Text(
          '¿Seguro que deseas eliminar este usuario?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Cancelar'),
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
      widget.onDelete?.call();
    }
  }

  Future<void> _confirmPasswordReset(BuildContext context) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Restablecer contraseña'),
        content: Text(
          'Se enviará un correo de restablecimiento a ${widget.employee.email}. ¿Desea continuar?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            style: TextButton.styleFrom(foregroundColor: AppColors.primary),
            child: const Text('Enviar'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      widget.onPasswordReset?.call();
    }
  }

  Widget _buildDetailItem(IconData icon, String text) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(
          icon,
          size: 14,
          color: AppColors.textSecondary,
        ),
        const SizedBox(width: 6),
        Text(
          text,
          style: const TextStyle(
            color: AppColors.textSecondary,
            fontSize: 13,
          ),
        ),
      ],
    );
  }
}
