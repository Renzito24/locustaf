import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/app_theme.dart';
import '../../../authentication/presentation/providers/auth_provider.dart';
import '../../../../core/models/user_model.dart';
import '../../../workplaces/presentation/providers/workplace_notifier.dart';
import '../../../workplaces/data/models/workplace_model.dart';
import '../widgets/profile_header.dart';
import '../widgets/profile_components.dart';
import '../providers/profile_provider.dart';

class ProfileScreen extends ConsumerStatefulWidget {
  const ProfileScreen({super.key});

  @override
  ConsumerState<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends ConsumerState<ProfileScreen> {
  bool _isEditing = false;

  final _formKey = GlobalKey<FormState>();
  final _nombreController = TextEditingController();
  final _apellidoController = TextEditingController();
  final _telefonoController = TextEditingController();

  @override
  void dispose() {
    _nombreController.dispose();
    _apellidoController.dispose();
    _telefonoController.dispose();
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
              ProfileEditToggle(
                isEditing: _isEditing,
                isLoading: updateState.isLoading,
                onEdit: () => setState(() => _isEditing = true),
                onCancel: () {
                  setState(() => _isEditing = false);
                  _populateFields(user);
                  ref.read(profileUpdateProvider.notifier).reset();
                },
                onSave: () => _saveProfile(user),
              ),
              const SizedBox(height: 16),
              if (_isEditing)
                ProfileEditForm(
                  user: user,
                  formKey: _formKey,
                  nombreController: _nombreController,
                  apellidoController: _apellidoController,
                  telefonoController: _telefonoController,
                )
              else
                ProfileReadOnlySection(
                  user: user,
                  workplacesAsync: workplacesAsync,
                ),
              const SizedBox(height: 16),
              const ProfileSecuritySection(),
            ],
          ),
        ),
      ),
    );
  }
}
