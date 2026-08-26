import 'package:flutter/material.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/models/user_model.dart';

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
        decoration: AppTheme.cardDecoration(isHovered: _isHovered),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: AppTheme.goldGradient,
                ),
                child: Center(
                  child: Text(
                    _initials,
                    style: const TextStyle(
                      color: AppColors.textPrimary,
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 1,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 16),

              Expanded(
                child: Column(
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
                        _buildDetailItem(Icons.email_outlined, employee.email),
                        _buildDetailItem(
                            Icons.badge_outlined, 'DNI: ${employee.dni}'),
                        if (employee.telefono != null &&
                            employee.telefono!.isNotEmpty)
                          _buildDetailItem(
                              Icons.phone_outlined, employee.telefono!),
                      ],
                    ),
                  ],
                ),
              ),

              const SizedBox(width: 16),

              AppTheme.badge(
                label: employee.isActive ? 'Activo' : 'Inactivo',
                bgColor: employee.isActive
                    ? AppColors.badgeActiveBg
                    : AppColors.badgeInactiveBg,
                textColor: employee.isActive
                    ? AppColors.badgeActiveText
                    : AppColors.badgeInactiveText,
              ),

              const SizedBox(width: 8),

              if (employee.rol == UserRole.supervisor) ...[
                AppTheme.badge(
                  label: employee.rol.label,
                  bgColor: AppColors.warning.withValues(alpha: 0.2),
                  textColor: AppColors.warning,
                ),
                const SizedBox(width: 8),
              ],

              PopupMenuButton<String>(
                icon: const Icon(
                  Icons.more_vert,
                  color: AppColors.textMuted,
                ),
                color: AppColors.cardDark,
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
                        child: Row(
                          children: const [
                            Icon(Icons.edit_outlined, size: 18,
                                color: AppColors.textMuted),
                            SizedBox(width: 8),
                            Text('Editar',
                                style:
                                    TextStyle(color: AppColors.textWhite)),
                          ],
                        ),
                      ),
                    );
                  }
                  if (widget.onHistory != null) {
                    items.add(
                      PopupMenuItem<String>(
                        value: 'history',
                        child: Row(
                          children: const [
                            Icon(Icons.history_outlined, size: 18,
                                color: AppColors.textMuted),
                            SizedBox(width: 8),
                            Text('Historial',
                                style:
                                    TextStyle(color: AppColors.textWhite)),
                          ],
                        ),
                      ),
                    );
                  }
                  if (widget.onPasswordReset != null) {
                    items.add(PopupMenuDivider(
                        color: AppColors.gold.withValues(alpha: 0.2)));
                    items.add(
                      PopupMenuItem<String>(
                        value: 'passwordReset',
                        child: Row(
                          children: const [
                            Icon(Icons.lock_reset_outlined, size: 18,
                                color: AppColors.textMuted),
                            SizedBox(width: 8),
                            Text('Restablecer contraseña',
                                style:
                                    TextStyle(color: AppColors.textWhite)),
                          ],
                        ),
                      ),
                    );
                  }
                  if (widget.onToggleActive != null) {
                    items.addAll([
                      if (items.isNotEmpty)
                        PopupMenuDivider(
                            color: AppColors.gold.withValues(alpha: 0.2)),
                      PopupMenuItem<String>(
                        value: 'toggleActive',
                        child: Row(
                          children: [
                            Icon(
                              employee.isActive
                                  ? Icons.block_flipped
                                  : Icons.check_circle_outline,
                              size: 18,
                              color: employee.isActive
                                  ? AppColors.error
                                  : AppColors.success,
                            ),
                            const SizedBox(width: 8),
                            Text(
                              employee.isActive ? 'Desactivar' : 'Activar',
                              style: TextStyle(
                                color: employee.isActive
                                    ? AppColors.error
                                    : AppColors.success,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ]);
                  }
                  if (widget.onDelete != null) {
                    items.addAll([
                      if (items.isNotEmpty)
                        PopupMenuDivider(
                            color: AppColors.gold.withValues(alpha: 0.2)),
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
        backgroundColor: AppColors.cardDark,
        title: const Text('Eliminar usuario',
            style: TextStyle(color: AppColors.textWhite)),
        content: const Text(
          '¿Seguro que deseas eliminar este usuario?',
          style: TextStyle(color: AppColors.textMuted),
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppTheme.radiusXl),
          side: BorderSide(
              color: AppColors.gold.withValues(alpha: 0.18)),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Cancelar',
                style: TextStyle(color: AppColors.textMuted)),
          ),
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            style:
                TextButton.styleFrom(foregroundColor: AppColors.error),
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
        backgroundColor: AppColors.cardDark,
        title: const Text('Restablecer contraseña',
            style: TextStyle(color: AppColors.textWhite)),
        content: Text(
          'Se enviará un correo de restablecimiento a ${widget.employee.email}. ¿Desea continuar?',
          style: const TextStyle(color: AppColors.textMuted),
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppTheme.radiusXl),
          side: BorderSide(
              color: AppColors.gold.withValues(alpha: 0.18)),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Cancelar',
                style: TextStyle(color: AppColors.textMuted)),
          ),
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            style:
                TextButton.styleFrom(foregroundColor: AppColors.gold),
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
