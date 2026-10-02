import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/config/app_version.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/widgets/widgets.dart';
import '../../../../core/models/user_model.dart';
import '../../../workplaces/data/models/workplace_model.dart';
import '../providers/profile_provider.dart';
import 'profile_info_card.dart';
import 'profile_role_badge.dart';
import 'profile_status_badge.dart';

class ProfileEditToggle extends StatelessWidget {
  final bool isEditing;
  final bool isLoading;
  final VoidCallback onEdit;
  final VoidCallback onCancel;
  final VoidCallback onSave;

  const ProfileEditToggle({
    super.key,
    required this.isEditing,
    required this.isLoading,
    required this.onEdit,
    required this.onCancel,
    required this.onSave,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        if (isEditing) ...[
          OutlinedButton.icon(
            onPressed: isLoading ? null : onCancel,
            icon: const Icon(Icons.close, size: 18),
            label: const Text('Cancelar'),
            style: OutlinedButton.styleFrom(
              foregroundColor: AppColors.textMuted,
              side: BorderSide(color: AppColors.gold.withValues(alpha: 0.3)),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppTheme.radiusSm)),
            ),
          ),
          const SizedBox(width: 12),
          DecoratedBox(
            decoration: BoxDecoration(
              gradient: AppTheme.goldGradient,
              borderRadius: BorderRadius.circular(AppTheme.radiusSm),
            ),
            child: ElevatedButton.icon(
              onPressed: isLoading ? null : onSave,
              icon: isLoading
                  ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                    )
                  : const Icon(Icons.check, size: 18),
              label: Text(isLoading ? 'Guardando...' : 'Guardar'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.transparent,
                shadowColor: Colors.transparent,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                textStyle: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppTheme.radiusSm)),
              ),
            ),
          ),
        ] else
          OutlinedButton.icon(
            onPressed: onEdit,
            icon: const Icon(Icons.edit_outlined, size: 18),
            label: const Text('Editar perfil'),
            style: OutlinedButton.styleFrom(
              foregroundColor: AppColors.gold,
              side: BorderSide(color: AppColors.gold.withValues(alpha: 0.4)),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppTheme.radiusSm)),
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
            ),
          ),
      ],
    );
  }
}

class ProfileEditForm extends StatelessWidget {
  final UserModel user;
  final GlobalKey<FormState> formKey;
  final TextEditingController nombreController;
  final TextEditingController apellidoController;
  final TextEditingController telefonoController;

  const ProfileEditForm({
    super.key,
    required this.user,
    required this.formKey,
    required this.nombreController,
    required this.apellidoController,
    required this.telefonoController,
  });

  Widget _readOnlyField(IconData icon, String label, String value) {
    return Row(
      children: [
        Icon(icon, size: 20, color: AppColors.textMuted),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label, style: const TextStyle(fontSize: 12, color: AppColors.textMuted)),
              const SizedBox(height: 2),
              Text(
                value,
                style: const TextStyle(fontSize: 14, color: AppColors.textWhite, fontWeight: FontWeight.w500),
              ),
            ],
          ),
        ),
        Icon(Icons.lock_outline, size: 14, color: AppColors.textMuted.withValues(alpha: 0.5)),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return AppCard(
      child: Form(
        key: formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const AppCardHeader(
              icon: Icons.edit_outlined,
              title: 'Editar información',
            ),
            const SizedBox(height: 20),
            TextFormField(
              controller: nombreController,
              style: const TextStyle(color: AppColors.textWhite),
              decoration: AppTheme.inputDecoration(label: 'Nombre', icon: Icons.person_outline),
              validator: (v) => (v == null || v.trim().isEmpty) ? 'El nombre es obligatorio' : null,
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: apellidoController,
              style: const TextStyle(color: AppColors.textWhite),
              decoration: AppTheme.inputDecoration(label: 'Apellido', icon: Icons.person_outline),
              validator: (v) => (v == null || v.trim().isEmpty) ? 'El apellido es obligatorio' : null,
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: telefonoController,
              style: const TextStyle(color: AppColors.textWhite),
              decoration: AppTheme.inputDecoration(label: 'Teléfono (opcional)', icon: Icons.phone_outlined),
              keyboardType: TextInputType.phone,
            ),
            const SizedBox(height: 16),
            _readOnlyField(Icons.badge_outlined, 'DNI', user.dni),
            const SizedBox(height: 8),
            _readOnlyField(Icons.email_outlined, 'Correo electrónico', user.email),
          ],
        ),
      ),
    );
  }
}

class ProfileReadOnlySection extends StatelessWidget {
  final UserModel user;
  final AsyncValue<List<WorkplaceModel>> workplacesAsync;

  const ProfileReadOnlySection({
    super.key,
    required this.user,
    required this.workplacesAsync,
  });

  String _formatDate(DateTime date) {
    const months = [
      'ene', 'feb', 'mar', 'abr', 'may', 'jun',
      'jul', 'ago', 'sep', 'oct', 'nov', 'dic',
    ];
    return '${date.day} ${months[date.month - 1]} ${date.year}';
  }

  @override
  Widget build(BuildContext context) {
    final workplaceName = workplacesAsync.when(
      data: (workplaces) {
        final w = workplaces.where((w) => w.id == user.lugarDeTrabajoId).firstOrNull;
        return w?.nombre ?? (user.lugarDeTrabajoId != null ? '—' : 'No asignado');
      },
      loading: () => 'Cargando...',
      error: (_, _) => '—',
    );

    return Column(
      children: [
        ProfileInfoCard(
          title: 'Información Personal',
          titleIcon: Icons.person_outline,
          rows: [
            ProfileInfoRow(icon: Icons.person_outline, label: 'Nombre completo', value: user.nombreCompleto),
            ProfileInfoRow(icon: Icons.email_outlined, label: 'Correo electrónico', value: user.email),
            ProfileInfoRow(icon: Icons.badge_outlined, label: 'DNI', value: user.dni),
            if (user.telefono != null)
              ProfileInfoRow(icon: Icons.phone_outlined, label: 'Teléfono', value: user.telefono!),
          ],
        ),
        const SizedBox(height: 16),
        ProfileInfoCard(
          title: 'Información Laboral',
          titleIcon: Icons.work_outline,
          rows: [
            ProfileInfoRow(
              icon: Icons.badge_outlined,
              label: 'Rol',
              child: ProfileRoleBadge(role: user.rol),
            ),
            ProfileInfoRow(icon: Icons.business_outlined, label: 'Lugar de trabajo', value: workplaceName),
            ProfileInfoRow(
              icon: Icons.toggle_on_outlined,
              label: 'Estado',
              child: ProfileStatusBadge(isActive: user.isActive),
            ),
          ],
        ),
        const SizedBox(height: 16),
        ProfileInfoCard(
          title: 'Sistema',
          titleIcon: Icons.settings_outlined,
          rows: [
            ProfileInfoRow(icon: Icons.info_outline, label: 'Versión', value: appVersion),
            ProfileInfoRow(icon: Icons.calendar_today_outlined, label: 'Fecha de creación', value: _formatDate(user.createdAt)),
            if (user.updatedAt != null)
              ProfileInfoRow(icon: Icons.update_outlined, label: 'Última actualización', value: _formatDate(user.updatedAt!)),
          ],
        ),
      ],
    );
  }
}

class ProfileSecuritySection extends ConsumerStatefulWidget {
  const ProfileSecuritySection({super.key});

  @override
  ConsumerState<ProfileSecuritySection> createState() => _ProfileSecuritySectionState();
}

class _ProfileSecuritySectionState extends ConsumerState<ProfileSecuritySection> {
  bool _showPasswordSection = false;
  final _passwordFormKey = GlobalKey<FormState>();
  final _currentPasswordController = TextEditingController();
  final _newPasswordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  bool _obscureCurrent = true;
  bool _obscureNew = true;
  bool _obscureConfirm = true;

  @override
  void dispose() {
    _currentPasswordController.dispose();
    _newPasswordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  Future<void> _changePassword() async {
    if (!_passwordFormKey.currentState!.validate()) return;
    await ref.read(passwordChangeProvider.notifier).changePassword(
      currentPassword: _currentPasswordController.text,
      newPassword: _newPasswordController.text,
    );
  }

  @override
  Widget build(BuildContext context) {
    ref.listen<PasswordChangeState>(passwordChangeProvider, (prev, next) {
      if (next.success != null) {
        ScaffoldMessenger.of(context).showSnackBar(AppTheme.successSnackBar(next.success!));
        _currentPasswordController.clear();
        _newPasswordController.clear();
        _confirmPasswordController.clear();
        setState(() => _showPasswordSection = false);
        ref.read(passwordChangeProvider.notifier).reset();
      } else if (next.error != null) {
        ScaffoldMessenger.of(context).showSnackBar(AppTheme.errorSnackBar(next.error!));
        ref.read(passwordChangeProvider.notifier).reset();
      }
    });

    final isLoading = ref.watch(passwordChangeProvider).isLoading;

    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          InkWell(
            onTap: () => setState(() => _showPasswordSection = !_showPasswordSection),
            child: Row(
              children: [
                const Icon(Icons.lock_outline, size: 18, color: AppColors.gold),
                const SizedBox(width: 8),
                const Expanded(
                  child: Text(
                    'Seguridad',
                    style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: AppColors.textWhite),
                  ),
                ),
                Icon(
                  _showPasswordSection ? Icons.expand_less : Icons.expand_more,
                  color: AppColors.textMuted,
                ),
              ],
            ),
          ),
          if (_showPasswordSection) ...[
            const SizedBox(height: 20),
            Form(
              key: _passwordFormKey,
              child: Column(
                children: [
                  TextFormField(
                    controller: _currentPasswordController,
                    obscureText: _obscureCurrent,
                    style: const TextStyle(color: AppColors.textWhite),
                    decoration: AppTheme.inputDecoration(
                      label: 'Contraseña actual',
                      icon: Icons.lock_outline,
                    ).copyWith(
                      suffixIcon: IconButton(
                        icon: Icon(_obscureCurrent ? Icons.visibility_off : Icons.visibility, color: AppColors.textMuted, size: 20),
                        onPressed: () => setState(() => _obscureCurrent = !_obscureCurrent),
                      ),
                    ),
                    validator: (v) => (v == null || v.isEmpty) ? 'La contraseña actual es obligatoria' : null,
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _newPasswordController,
                    obscureText: _obscureNew,
                    style: const TextStyle(color: AppColors.textWhite),
                    decoration: AppTheme.inputDecoration(
                      label: 'Nueva contraseña',
                      icon: Icons.lock_outline,
                    ).copyWith(
                      suffixIcon: IconButton(
                        icon: Icon(_obscureNew ? Icons.visibility_off : Icons.visibility, color: AppColors.textMuted, size: 20),
                        onPressed: () => setState(() => _obscureNew = !_obscureNew),
                      ),
                    ),
                    validator: (v) {
                      if (v == null || v.isEmpty) return 'La nueva contraseña es obligatoria';
                      if (v.length < 6) return 'Mínimo 6 caracteres';
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _confirmPasswordController,
                    obscureText: _obscureConfirm,
                    style: const TextStyle(color: AppColors.textWhite),
                    decoration: AppTheme.inputDecoration(
                      label: 'Confirmar contraseña',
                      icon: Icons.lock_outline,
                    ).copyWith(
                      suffixIcon: IconButton(
                        icon: Icon(_obscureConfirm ? Icons.visibility_off : Icons.visibility, color: AppColors.textMuted, size: 20),
                        onPressed: () => setState(() => _obscureConfirm = !_obscureConfirm),
                      ),
                    ),
                    validator: (v) {
                      if (v == null || v.isEmpty) return 'Confirmá la contraseña';
                      if (v != _newPasswordController.text) return 'Las contraseñas no coinciden';
                      return null;
                    },
                  ),
                  const SizedBox(height: 20),
                  SizedBox(
                    width: double.infinity,
                    child: DecoratedBox(
                      decoration: BoxDecoration(
                        gradient: AppTheme.goldGradient,
                        borderRadius: BorderRadius.circular(AppTheme.radiusLg),
                      ),
                      child: ElevatedButton.icon(
                        onPressed: isLoading ? null : _changePassword,
                        icon: isLoading
                            ? const SizedBox(
                                width: 16,
                                height: 16,
                                child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                              )
                            : const Icon(Icons.lock_outline, size: 18),
                        label: Text(isLoading ? 'Cambiando...' : 'Cambiar contraseña'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.transparent,
                          shadowColor: Colors.transparent,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          textStyle: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(AppTheme.radiusLg),
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}
