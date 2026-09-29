import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/models/company_model.dart';
import '../../../../core/models/user_model.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/widgets/widgets.dart';
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
  bool _aceptaTerminos = false;
  bool _aceptaPrivacidad = false;

  Future<void> _showLegalDocument(String title, String content) async {
    final isMobile = AppTheme.isMobile(context);
    await showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: AppColors.bgDarkTop,
          title: Text(title, style: AppTheme.headingMd),
          content: SizedBox(
            width: isMobile ? double.maxFinite : 600,
            child: Scrollbar(
              thumbVisibility: true,
              child: SingleChildScrollView(
                child: Text(
                  content,
                  style: const TextStyle(color: AppColors.textSecondary, fontSize: 14, height: 1.5),
                ),
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cerrar', style: TextStyle(color: AppColors.gold)),
            ),
          ],
        );
      },
    );
  }

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
            child: AppCard(
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
                    const SizedBox(height: 12),
                    FormField<bool>(
                      initialValue: _aceptaTerminos,
                      validator: (v) => (v == true)
                          ? null
                          : 'Requerido para continuar.',
                      builder: (field) => Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.center,
                            children: [
                              Checkbox(
                                value: _aceptaTerminos,
                                activeColor: AppColors.gold,
                                checkColor: Colors.white,
                                side: const BorderSide(color: AppColors.textSecondary),
                                onChanged: state.isLoading
                                    ? null
                                    : (v) {
                                        setState(() => _aceptaTerminos = v ?? false);
                                        field.didChange(_aceptaTerminos);
                                      },
                              ),
                              Expanded(
                                child: GestureDetector(
                                  onTap: () => _showLegalDocument(
                                    'Términos y Condiciones (Borrador Académico)',
                                    'BORRADOR ACADÉMICO / PROVISIONAL - SUJETO A REVISIÓN LEGAL\n\n'
                                    '1. Objeto\n'
                                    'LOCUSTAF es un proyecto académico diseñado para la gestión de asistencia y administración de personal. Su uso es estrictamente educativo y no comercial.\n\n'
                                    '2. Uso de Geolocalización\n'
                                    'La plataforma captura la geolocalización del usuario (empleado) únicamente al momento de registrar su asistencia (Check-in / Check-out). Esta información es utilizada para verificar si el usuario se encuentra dentro del radio permitido de su lugar de trabajo.\n\n'
                                    '3. Responsabilidades\n'
                                    'Al ser un proyecto académico, no se ofrecen garantías de disponibilidad, integridad o seguridad de nivel empresarial. El administrador de la empresa asume la responsabilidad por los datos de sus empleados ingresados en el sistema.\n\n'
                                    '4. Documentación Médica y Justificativos\n'
                                    'El sistema permite la carga de documentos para justificar inasistencias. El administrador debe garantizar que tiene el consentimiento de sus empleados para manejar esta información en la plataforma.',
                                  ),
                                  child: const Text(
                                    'He leído y acepto los Términos y Condiciones.',
                                    style: TextStyle(
                                      color: AppColors.textWhite,
                                      fontSize: 13,
                                      decoration: TextDecoration.underline,
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                          if (field.hasError)
                            Padding(
                              padding: const EdgeInsets.only(left: 12),
                              child: Text(
                                field.errorText!,
                                style: const TextStyle(color: AppColors.error, fontSize: 12),
                              ),
                            ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 8),
                    FormField<bool>(
                      initialValue: _aceptaPrivacidad,
                      validator: (v) => (v == true)
                          ? null
                          : 'Requerido para continuar.',
                      builder: (field) => Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.center,
                            children: [
                              Checkbox(
                                value: _aceptaPrivacidad,
                                activeColor: AppColors.gold,
                                checkColor: Colors.white,
                                side: const BorderSide(color: AppColors.textSecondary),
                                onChanged: state.isLoading
                                    ? null
                                    : (v) {
                                        setState(() => _aceptaPrivacidad = v ?? false);
                                        field.didChange(_aceptaPrivacidad);
                                      },
                              ),
                              Expanded(
                                child: GestureDetector(
                                  onTap: () => _showLegalDocument(
                                    'Política de Privacidad (Borrador Académico)',
                                    'BORRADOR ACADÉMICO / PROVISIONAL - SUJETO A REVISIÓN LEGAL\n\n'
                                    '1. Recopilación de Datos\n'
                                    'Recolectamos información personal básica (nombre, DNI, correo, teléfono) y datos de ubicación (solo durante el registro de asistencia) con fines funcionales del sistema académico.\n\n'
                                    '2. Almacenamiento\n'
                                    'Los datos se almacenan en infraestructura en la nube (Google Cloud / Firebase). Al ser un entorno de prueba, los datos podrían ser eliminados o reseteados sin previo aviso.\n\n'
                                    '3. Uso de la Información\n'
                                    'La información será utilizada exclusivamente para el funcionamiento de LOCUSTAF (gestión de personal, control de asistencia, reportes internos de la empresa).\n\n'
                                    '4. Eliminación de Datos\n'
                                    'Un usuario puede ser marcado como "inactivo" o "eliminado" de forma lógica en la base de datos para no perder el historial de asistencias de la empresa, de acuerdo a la lógica actual del sistema.',
                                  ),
                                  child: const Text(
                                    'He leído y acepto la Política de Privacidad.',
                                    style: TextStyle(
                                      color: AppColors.textWhite,
                                      fontSize: 13,
                                      decoration: TextDecoration.underline,
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                          if (field.hasError)
                            Padding(
                              padding: const EdgeInsets.only(left: 12),
                              child: Text(
                                field.errorText!,
                                style: const TextStyle(color: AppColors.error, fontSize: 12),
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
