import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/models/company_model.dart';
import '../../../../core/models/user_model.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../authentication/presentation/providers/auth_provider.dart';
import '../providers/onboarding_provider.dart';

class OnboardingScreen extends ConsumerStatefulWidget {
  const OnboardingScreen({super.key});

  @override
  ConsumerState<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends ConsumerState<OnboardingScreen> {
  final _formKey = GlobalKey<FormState>();

  // Datos personales
  final _nombreController = TextEditingController();
  final _apellidoController = TextEditingController();
  final _dniController = TextEditingController();
  final _telefonoController = TextEditingController();
  final _direccionController = TextEditingController();
  final _localidadController = TextEditingController();
  final _provinciaController = TextEditingController();
  final _codigoPostalController = TextEditingController();

  // Credenciales
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  // Empresa
  final _empresaController = TextEditingController();
  final _razonSocialController = TextEditingController();
  final _cuitController = TextEditingController();
  final _empresaEmailController = TextEditingController();
  bool _aceptaPoliticas = false;

  @override
  void dispose() {
    _nombreController.dispose();
    _apellidoController.dispose();
    _dniController.dispose();
    _telefonoController.dispose();
    _direccionController.dispose();
    _localidadController.dispose();
    _provinciaController.dispose();
    _codigoPostalController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    _empresaController.dispose();
    _razonSocialController.dispose();
    _cuitController.dispose();
    _empresaEmailController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    final authUser = ref.read(authServiceProvider).currentUser;
    if (authUser == null) return;

    final profile = UserModel(
      id: authUser.uid,
      nombre: _nombreController.text.trim(),
      apellido: _apellidoController.text.trim(),
      email: authUser.email ?? '',
      dni: _dniController.text.trim(),
      telefono: _telefonoController.text.trim().isEmpty
          ? null
          : _telefonoController.text.trim(),
      localidad: _localidadController.text.trim().isEmpty
          ? null
          : _localidadController.text.trim(),
      provincia: _provinciaController.text.trim().isEmpty
          ? null
          : _provinciaController.text.trim(),
      codigoPostal: _codigoPostalController.text.trim().isEmpty
          ? null
          : _codigoPostalController.text.trim(),
      rol: UserRole.admin,
      createdAt: DateTime.now(),
    );

    final company = CompanyModel(
      id: '',
      nombreComercial: _empresaController.text.trim(),
      razonSocial: _razonSocialController.text.trim(),
      cuit: _cuitController.text.trim(),
      email: _empresaEmailController.text.trim().isEmpty
          ? null
          : _empresaEmailController.text.trim(),
      createdBy: authUser.uid,
      createdAt: DateTime.now(),
    );

    await ref.read(onboardingProvider.notifier).createCompanyAndAdmin(
          profile: profile,
          company: company,
        );

    // Vincula la contraseña elegida a la cuenta para que el usuario pueda
    // iniciar sesión luego con su correo y esta contraseña.
    final password = _passwordController.text;
    if (password.isNotEmpty) {
      await ref.read(authRepositoryProvider).linkPassword(
            email: authUser.email ?? '',
            password: password,
          );
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(onboardingProvider);
    final isMobile = AppTheme.isMobile(context);

    ref.listen<OnboardingState>(onboardingProvider, (prev, next) {
      if (next.isLoading) return;
      if (next.error != null) {
        ScaffoldMessenger.of(context).showSnackBar(
          AppTheme.errorSnackBar(next.error!),
        );
      } else if (prev?.isLoading == true) {
        context.go('/dashboard');
      }
    });

    return Scaffold(
      backgroundColor: AppColors.bgDarkTop,
      body: Center(
        child: SingleChildScrollView(
          padding: EdgeInsets.all(isMobile ? 16 : 32),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 560),
            child: Container(
              decoration: AppTheme.cardDecoration(),
              padding: const EdgeInsets.all(28),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    ShaderMask(
                      shaderCallback: (bounds) =>
                          AppTheme.goldGradient.createShader(bounds),
                      child: const Text(
                        'LOCUSTAF',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 3,
                        ),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text('Completá tus datos y creá tu empresa',
                        style: AppTheme.headingMd),
                    const SizedBox(height: 4),
                    Text(
                      'Vas a quedar como administrador de tu empresa.',
                      style: AppTheme.bodyMd,
                    ),
                    const SizedBox(height: 24),
                    Text('Datos personales', style: AppTheme.headingMd),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: TextFormField(
                            controller: _nombreController,
                            style: const TextStyle(color: AppColors.textWhite),
                            decoration: AppTheme.inputDecoration(
                              label: 'Nombre *',
                              icon: Icons.person_outline,
                            ),
                            validator: (v) =>
                                (v == null || v.trim().isEmpty) ? 'Requerido' : null,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: TextFormField(
                            controller: _apellidoController,
                            style: const TextStyle(color: AppColors.textWhite),
                            decoration: AppTheme.inputDecoration(
                              label: 'Apellido *',
                              icon: Icons.person_outline,
                            ),
                            validator: (v) =>
                                (v == null || v.trim().isEmpty) ? 'Requerido' : null,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: _dniController,
                      keyboardType: TextInputType.number,
                      style: const TextStyle(color: AppColors.textWhite),
                      decoration: AppTheme.inputDecoration(
                        label: 'DNI *',
                        icon: Icons.badge_outlined,
                      ),
                      validator: (v) =>
                          (v == null || v.trim().isEmpty) ? 'Requerido' : null,
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: _telefonoController,
                      keyboardType: TextInputType.phone,
                      style: const TextStyle(color: AppColors.textWhite),
                      decoration: AppTheme.inputDecoration(
                        label: 'Teléfono',
                        icon: Icons.phone_outlined,
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: _direccionController,
                      style: const TextStyle(color: AppColors.textWhite),
                      decoration: AppTheme.inputDecoration(
                        label: 'Domicilio',
                        icon: Icons.home_outlined,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: TextFormField(
                            controller: _localidadController,
                            style: const TextStyle(color: AppColors.textWhite),
                            decoration: AppTheme.inputDecoration(
                              label: 'Localidad *',
                              icon: Icons.location_city_outlined,
                            ),
                            validator: (v) => (v == null || v.trim().isEmpty)
                                ? 'Requerido'
                                : null,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: TextFormField(
                            controller: _provinciaController,
                            style: const TextStyle(color: AppColors.textWhite),
                            decoration: AppTheme.inputDecoration(
                              label: 'Provincia *',
                              icon: Icons.map_outlined,
                            ),
                            validator: (v) => (v == null || v.trim().isEmpty)
                                ? 'Requerido'
                                : null,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: _codigoPostalController,
                      keyboardType: TextInputType.number,
                      style: const TextStyle(color: AppColors.textWhite),
                      decoration: AppTheme.inputDecoration(
                        label: 'Código postal *',
                        icon: Icons.numbers_outlined,
                      ),
                      validator: (v) => (v == null || v.trim().isEmpty)
                          ? 'Requerido'
                          : null,
                    ),
                    const SizedBox(height: 24),
                    Text('Credenciales de acceso', style: AppTheme.headingMd),
                    const SizedBox(height: 4),
                    Text(
                      'Elegí una contraseña para poder ingresar con tu correo y contraseña.',
                      style: AppTheme.bodyMd,
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: _passwordController,
                      obscureText: true,
                      style: const TextStyle(color: AppColors.textWhite),
                      decoration: AppTheme.inputDecoration(
                        label: 'Contraseña *',
                        icon: Icons.lock_outline,
                      ),
                      validator: (v) {
                        if (v == null || v.isEmpty) return 'Requerido';
                        if (v.length < 6) {
                          return 'Mínimo 6 caracteres';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: _confirmPasswordController,
                      obscureText: true,
                      style: const TextStyle(color: AppColors.textWhite),
                      decoration: AppTheme.inputDecoration(
                        label: 'Confirmar contraseña *',
                        icon: Icons.lock_outline,
                      ),
                      validator: (v) {
                        if (v == null || v.isEmpty) return 'Requerido';
                        if (v != _passwordController.text) {
                          return 'Las contraseñas no coinciden';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 24),
                    Text('Datos de la empresa', style: AppTheme.headingMd),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: _empresaController,
                      style: const TextStyle(color: AppColors.textWhite),
                      decoration: AppTheme.inputDecoration(
                        label: 'Nombre comercial *',
                        icon: Icons.business_outlined,
                      ),
                      validator: (v) =>
                          (v == null || v.trim().isEmpty) ? 'Requerido' : null,
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: _razonSocialController,
                      style: const TextStyle(color: AppColors.textWhite),
                      decoration: AppTheme.inputDecoration(
                        label: 'Razón social *',
                        icon: Icons.business_outlined,
                      ),
                      validator: (v) =>
                          (v == null || v.trim().isEmpty) ? 'Requerido' : null,
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: _cuitController,
                      style: const TextStyle(color: AppColors.textWhite),
                      decoration: AppTheme.inputDecoration(
                        label: 'CUIT *',
                        icon: Icons.numbers_outlined,
                      ),
                      validator: (v) =>
                          (v == null || v.trim().isEmpty) ? 'Requerido' : null,
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: _empresaEmailController,
                      style: const TextStyle(color: AppColors.textWhite),
                      decoration: AppTheme.inputDecoration(
                        label: 'Email de la empresa',
                        icon: Icons.email_outlined,
                      ),
                    ),
                    const SizedBox(height: 24),
                    Text('Términos y políticas', style: AppTheme.headingMd),
                    const SizedBox(height: 4),
                    Text(
                      'Al continuar confirmás que leíste y aceptás los términos '
                      'de uso, las políticas de privacidad y el tratamiento de '
                      'los datos personales de tus empleados.',
                      style: AppTheme.bodyMd,
                    ),
                    const SizedBox(height: 12),
                    FormField<bool>(
                      initialValue: _aceptaPoliticas,
                      validator: (v) => (v == true)
                          ? null
                          : 'Debés aceptar los términos y políticas para continuar.',
                      builder: (field) => Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          InkWell(
                            onTap: state.isLoading
                                ? null
                                : () {
                                    setState(() =>
                                        _aceptaPoliticas = !_aceptaPoliticas);
                                    field.didChange(_aceptaPoliticas);
                                  },
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Checkbox(
                                  value: _aceptaPoliticas,
                                  activeColor: AppColors.gold,
                                  checkColor: Colors.white,
                                  side: const BorderSide(
                                    color: AppColors.textSecondary,
                                  ),
                                  onChanged: state.isLoading
                                      ? null
                                      : (v) {
                                          setState(() => _aceptaPoliticas = v ?? false);
                                          field.didChange(_aceptaPoliticas);
                                        },
                                ),
                                const Expanded(
                                  child: Padding(
                                    padding: EdgeInsets.only(top: 12),
                                    child: Text(
                                      'Acepto los términos y condiciones y las '
                                      'políticas de uso y privacidad de LOCUSTAF.',
                                      style: TextStyle(
                                        color: AppColors.textWhite,
                                        fontSize: 13,
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          if (field.hasError)
                            Padding(
                              padding: const EdgeInsets.only(left: 12),
                              child: Text(
                                field.errorText!,
                                style: const TextStyle(
                                  color: AppColors.error,
                                  fontSize: 12,
                                ),
                              ),
                            ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 24),
                    SizedBox(
                      width: double.infinity,
                      child: DecoratedBox(
                        decoration: BoxDecoration(
                          gradient: AppTheme.goldGradient,
                          borderRadius: BorderRadius.circular(AppTheme.radiusLg),
                        ),
                        child: Material(
                          color: Colors.transparent,
                          child: InkWell(
                            borderRadius:
                                BorderRadius.circular(AppTheme.radiusLg),
                            onTap: state.isLoading ? null : _submit,
                            child: Padding(
                              padding: const EdgeInsets.symmetric(vertical: 14),
                              child: Center(
                                child: state.isLoading
                                    ? const SizedBox(
                                        width: 20,
                                        height: 20,
                                        child: CircularProgressIndicator(
                                            strokeWidth: 2, color: Colors.white),
                                      )
                                    : const Text(
                                        'Crear mi empresa',
                                        style: TextStyle(
                                          color: Colors.white,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
