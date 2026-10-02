import 'package:flutter/material.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/models/user_model.dart';
import '../../../../core/widgets/widgets.dart';
import 'employee_card_components.dart';

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
      child: AppCard(
        isHovered: _isHovered,
        padding: const EdgeInsets.all(16),
        child: Row(
            children: [
              EmployeeAvatar(initials: _initials),
              const SizedBox(width: 16),
              Expanded(
                child: EmployeeDetails(employee: employee),
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
              EmployeeActionsMenu(
                employee: employee,
                onEdit: widget.onEdit,
                onToggleActive: widget.onToggleActive,
                onHistory: widget.onHistory,
                onDelete: widget.onDelete,
                onPasswordReset: widget.onPasswordReset,
              ),
            ],
          ),
        ),
    );
  }
}
