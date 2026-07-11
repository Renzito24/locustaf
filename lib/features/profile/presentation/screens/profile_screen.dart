import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../authentication/presentation/providers/auth_provider.dart';
import '../../../authentication/data/models/user_model.dart';
import '../../../workplaces/presentation/providers/workplace_notifier.dart';
import '../../../workplaces/data/models/workplace_model.dart';
import '../widgets/profile_header.dart';
import '../widgets/profile_info_card.dart';
import '../widgets/profile_role_badge.dart';
import '../widgets/profile_status_badge.dart';
import '../providers/profile_provider.dart';

class ProfileScreen extends ConsumerStatefulWidget {
  const ProfileScreen({super.key});

  @override
  ConsumerState<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends ConsumerState<ProfileScreen> {
  bool _isEditing = false;
  bool _showPasswordSection = false;

  final _formKey = GlobalKey<FormState>();
  final _nombreController = TextEditingController();
  final _apellidoController = TextEditingController();
  final _telefonoController = TextEditingController();

  final _currentPasswordController = TextEditingController();
  final _newPasswordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  final _passwordFormKey = GlobalKey<FormState>();
  bool _obscureCurrent = true;
  bool _obscureNew = true;
  bool _obscureConfirm = true;

  @override
  void dispose() {
    _nombreController.dispose();
    _apellidoController.dispose();
    _telefonoController.dispose();
    _currentPasswordController.dispose();
    _newPasswordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  void _populateFields(UserModel user) {
    _nombreController.text = user.nombre;
    _apellidoController.text = user.apellido;
    _telefonoController.text = user.telefono ?? '';
  }

  Future<void> _saveProfile(UserModel user) async {
    if (!_formKey.currentState!.validate()) return;
    await ref.read(profileUpdateProvider.notifier).updateProfile(
      userId: user.id,
      nombre: _nombreController.text.trim(),
      apellido: _apellidoController.text.trim(),
      telefono: _telefonoController.text.trim().isEmpty ? null : _telefonoController.text.trim(),
    );
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
    final userAsync = ref.watch(currentAppUserProvider);
    final workplacesAsync = ref.watch(activeWorkplacesProvider);
    final updateState = ref.watch(profileUpdateProvider);

    ref.listen<ProfileUpdateState>(profileUpdateProvider, (prev, next) {
      if (next.success != null) {
        ScaffoldMessenger.of(context).showSnackBar(AppTheme.successSnackBar(next.success!));
        setState(() => _isEditing = false);
        ref.read(profileUpdateProvider.notifier).reset();
      } else if (next.error != null) {
        ScaffoldMessenger.of(context).showSnackBar(AppTheme.errorSnackBar(next.error!));
        ref.read(profileUpdateProvider.notifier).reset();
      }
    });

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

    return Padding(
      padding: const EdgeInsets.all(24),
      child: userAsync.when(
        data: (user) {
          if (user == null) {
            return AppTheme.emptyState(
              icon: Icons.person_off_outlined,
              title: 'No se pudo cargar el perfil',
              subtitle: 'Iniciá sesión para ver tu perfil.',
            );
          }
          if (!_isEditing) {
            _populateFields(user);
          }
          return _buildProfile(context, user, workplacesAsync, updateState);
        },
        loading: () => AppTheme.loadingState(),
        error: (error, _) => AppTheme.errorState('Error al cargar el perfil: ${error.toString()}'),
      ),
    );
  }

  Widget _buildProfile(
    BuildContext context,
    UserModel user,
    AsyncValue<List<WorkplaceModel>> workplacesAsync,
    ProfileUpdateState updateState,
  ) {
    return Center(
      child: SingleChildScrollView(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 600),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ProfileHeader(user: user),
              const SizedBox(height: 24),
              _buildEditToggle(user),
              const SizedBox(height: 16),
              if (_isEditing)
                _buildEditForm(user, updateState)
              else
                _buildReadOnlyProfile(user, workplacesAsync),
              const SizedBox(height: 16),
              _buildSecuritySection(user),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildEditToggle(UserModel user) {
    final updateState = ref.watch(profileUpdateProvider);
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        if (_isEditing) ...[
          OutlinedButton.icon(
            onPressed: updateState.isLoading
                ? null
                : () => setState(() {
                      _isEditing = false;
                      _populateFields(user);
                      ref.read(profileUpdateProvider.notifier).reset();
                    }),
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
              onPressed: updateState.isLoading ? null : () => _saveProfile(user),
              icon: updateState.isLoading
                  ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                    )
                  : const Icon(Icons.check, size: 18),
              label: Text(updateState.isLoading ? 'Guardando...' : 'Guardar'),
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
            onPressed: () => setState(() => _isEditing = true),
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

  Widget _buildEditForm(UserModel user, ProfileUpdateState updateState) {
    return Container(
      decoration: AppTheme.cardDecoration(),
      padding: const EdgeInsets.all(20),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.edit_outlined, size: 18, color: AppColors.gold),
                const SizedBox(width: 8),
                const Text(
                  'Editar información',
                  style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: AppColors.textWhite),
                ),
              ],
            ),
            const SizedBox(height: 20),
            TextFormField(
              controller: _nombreController,
              style: const TextStyle(color: AppColors.textWhite),
              decoration: AppTheme.inputDecoration(label: 'Nombre', icon: Icons.person_outline),
              validator: (v) => (v == null || v.trim().isEmpty) ? 'El nombre es obligatorio' : null,
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _apellidoController,
              style: const TextStyle(color: AppColors.textWhite),
              decoration: AppTheme.inputDecoration(label: 'Apellido', icon: Icons.person_outline),
              validator: (v) => (v == null || v.trim().isEmpty) ? 'El apellido es obligatorio' : null,
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _telefonoController,
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

  Widget _buildReadOnlyProfile(UserModel user, AsyncValue<List<WorkplaceModel>> workplacesAsync) {
    return Column(
      children: [
        _personalInfoCard(user),
        const SizedBox(height: 16),
        _workInfoCard(user, workplacesAsync),
        const SizedBox(height: 16),
        _systemInfoCard(user),
      ],
    );
  }

  Widget _personalInfoCard(UserModel user) {
    return ProfileInfoCard(
      title: 'Información Personal',
      titleIcon: Icons.person_outline,
      rows: [
        ProfileInfoRow(icon: Icons.person_outline, label: 'Nombre completo', value: user.nombreCompleto),
        ProfileInfoRow(icon: Icons.email_outlined, label: 'Correo electrónico', value: user.email),
        ProfileInfoRow(icon: Icons.badge_outlined, label: 'DNI', value: user.dni),
        if (user.telefono != null)
          ProfileInfoRow(icon: Icons.phone_outlined, label: 'Teléfono', value: user.telefono!),
      ],
    );
  }

  Widget _workInfoCard(
    UserModel user,
    AsyncValue<List<WorkplaceModel>> workplacesAsync,
  ) {
    final workplaceName = workplacesAsync.when(
      data: (workplaces) {
        final w = workplaces.where((w) => w.id == user.lugarDeTrabajoId).firstOrNull;
        return w?.nombre ?? (user.lugarDeTrabajoId != null ? '—' : 'No asignado');
      },
      loading: () => 'Cargando...',
      error: (_, _) => '—',
    );

    return ProfileInfoCard(
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
    );
  }

  Widget _systemInfoCard(UserModel user) {
    return ProfileInfoCard(
      title: 'Sistema',
      titleIcon: Icons.settings_outlined,
      rows: [
        ProfileInfoRow(icon: Icons.calendar_today_outlined, label: 'Fecha de creación', value: _formatDate(user.createdAt)),
        if (user.updatedAt != null)
          ProfileInfoRow(icon: Icons.update_outlined, label: 'Última actualización', value: _formatDate(user.updatedAt!)),
      ],
    );
  }

  Widget _buildSecuritySection(UserModel user) {
    return Container(
      decoration: AppTheme.cardDecoration(),
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          InkWell(
            onTap: () => setState(() => _showPasswordSection = !_showPasswordSection),
            child: Row(
              children: [
                Icon(Icons.lock_outline, size: 18, color: AppColors.gold),
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
                        onPressed: _changePassword,
                        icon: const Icon(Icons.lock_outline, size: 18),
                        label: const Text('Cambiar contraseña'),
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

  String _formatDate(DateTime date) {
    const months = [
      'ene', 'feb', 'mar', 'abr', 'may', 'jun',
      'jul', 'ago', 'sep', 'oct', 'nov', 'dic',
    ];
    return '${date.day} ${months[date.month - 1]} ${date.year}';
  }
}
