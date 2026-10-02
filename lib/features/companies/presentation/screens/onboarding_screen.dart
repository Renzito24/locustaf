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
import '../widgets/onboarding_form_sections.dart';

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
                    OnboardingPersonalDataSection(
                      nombreController: _nombreController,
                      apellidoController: _apellidoController,
                      dniController: _dniController,
                      telefonoController: _telefonoController,
                      direccionController: _direccionController,
                      localidadController: _localidadController,
                      provinciaController: _provinciaController,
                      codigoPostalController: _codigoPostalController,
                    ),
                    const SizedBox(height: 24),
                    OnboardingCredentialsSection(
                      passwordController: _passwordController,
                      confirmPasswordController: _confirmPasswordController,
                    ),
                    const SizedBox(height: 24),
                    OnboardingCompanyDataSection(
                      empresaController: _empresaController,
                      razonSocialController: _razonSocialController,
                      cuitController: _cuitController,
                      empresaEmailController: _empresaEmailController,
                    ),
                    const SizedBox(height: 24),
                    OnboardingLegalSection(
                      aceptaTerminos: _aceptaTerminos,
                      aceptaPrivacidad: _aceptaPrivacidad,
                      isLoading: state.isLoading,
                      onTerminosChanged: (v) {
                        setState(() => _aceptaTerminos = v);
                      },
                      onPrivacidadChanged: (v) {
                        setState(() => _aceptaPrivacidad = v);
                      },
                      onShowDocument: _showLegalDocument,
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
