import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/providers/firebase_providers.dart';
import '../../../../core/theme/app_theme.dart';
import '../providers/auth_provider.dart';

class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen>
    with SingleTickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  final emailController = TextEditingController();
  final passwordController = TextEditingController();

  bool isLoading = false;
  String? errorMessage;

  late final AnimationController _animController;
  late final Animation<double> _fadeAnim;
  late final Animation<Offset> _slideAnim;
  late final Animation<double> _logoScaleAnim;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final uri = GoRouterState.of(context).uri;
      if (uri.queryParameters['blocked'] == 'true') {
        _autoLogoutBlockedUser();
      }
    });

    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    );
    _fadeAnim = CurvedAnimation(
      parent: _animController,
      curve: const Interval(0.0, 1.0, curve: Curves.easeOut),
    );
    _slideAnim = Tween<Offset>(
      begin: const Offset(0, 0.08),
      end: Offset.zero,
    ).animate(
      CurvedAnimation(parent: _animController, curve: Curves.easeOutCubic),
    );
    _logoScaleAnim = Tween<double>(begin: 0.85, end: 1.0).animate(
      CurvedAnimation(
        parent: _animController,
        curve: const Interval(0.0, 0.7, curve: Curves.elasticOut),
      ),
    );
    _animController.forward();
  }

  Future<void> _autoLogoutBlockedUser() async {
    final authSvc = ref.read(authServiceProvider);
    await authSvc.logout();
    if (!mounted) return;
    setState(() {
      errorMessage = 'Tu cuenta ha sido desactivada o eliminada. Contactá al administrador.';
    });
  }

  String _mensajeError(Object error) {
    if (error is FirebaseAuthException) {
      switch (error.code) {
        case 'user-not-found':
          return 'No existe una cuenta con este correo electrónico';
        case 'wrong-password':
          return 'Contraseña incorrecta';
        case 'invalid-credential':
          return 'Correo o contraseña incorrectos';
        case 'invalid-email':
          return 'El correo electrónico no es válido';
        case 'user-disabled':
          return 'Esta cuenta ha sido deshabilitada';
        case 'too-many-requests':
          return 'Demasiados intentos. Intente más tarde';
        case 'network-request-failed':
          return 'Error de red. Verifique su conexión';
        case 'account-exists-with-different-credential':
          return 'Ya existe una cuenta con ese correo usando otro método de inicio de sesión';
        case 'popup-closed-by-user':
        case 'cancelled-popup-request':
          return 'Inicio de sesión cancelado';
        default:
          return 'Error al iniciar sesión: ${error.message ?? error.code}';
      }
    }
    final msg = error.toString().toLowerCase();
    if (msg.contains('idpiframe_initialization_failed') ||
        msg.contains('google sign-in is not initialized') ||
        msg.contains('clientid')) {
      return 'Error de configuración de Google Sign-In. Verificá el Client ID web en index.html.';
    }
    if (msg.contains('popup')) {
      return 'Inicio de sesión cancelado';
    }
    return 'Error inesperado. Intente nuevamente.';
  }

  Future<void> login() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      errorMessage = null;
      isLoading = true;
    });

    try {
      final authRepo = ref.read(authRepositoryProvider);
      final credential = await authRepo.login(
        emailController.text.trim(),
        passwordController.text,
      );

      final uid = credential.user?.uid;
      if (uid != null) {
        final svc = ref.read(firestoreServiceProvider);
        final userDoc = await svc.getDocument(path: 'users', documentId: uid);
        final isActive = userDoc?['isActive'] as bool? ?? true;
        final isDeleted = userDoc?['isDeleted'] as bool? ?? false;
        if (!isActive || isDeleted) {
          await authRepo.logout();
          if (!mounted) return;
          setState(() {
            errorMessage = 'Tu cuenta ha sido desactivada o eliminada. Contactá al administrador.';
          });
          return;
        }
      }

      if (!mounted) return;
      context.go('/dashboard');
    } on Exception catch (e) {
      setState(() {
        errorMessage = _mensajeError(e);
      });
    } finally {
      if (mounted) {
        setState(() {
          isLoading = false;
        });
      }
    }
  }

  Future<void> loginWithGoogle() async {
    setState(() {
      errorMessage = null;
      isLoading = true;
    });

    try {
      final authRepo = ref.read(authRepositoryProvider);
      final credential = await authRepo.loginWithGoogle();
      if (credential == null) {
        // Usuario canceló el flujo de Google.
        if (mounted) setState(() => isLoading = false);
        return;
      }
      if (!mounted) return;
      context.go('/dashboard');
    } on Exception catch (e) {
      if (mounted) {
        setState(() {
          errorMessage = _mensajeError(e);
        });
      }
    } finally {
      if (mounted) {
        setState(() {
          isLoading = false;
        });
      }
    }
  }

  @override
  void dispose() {
    emailController.dispose();
    passwordController.dispose();
    _animController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: const BoxDecoration(gradient: AppTheme.bgGradient),
        child: Stack(
          children: [
            Positioned(
              top: -80,
              right: -60,
              child: AppTheme.glowCircle(color: AppColors.gold.withValues(alpha: 0.10), size: 260),
            ),
            Positioned(
              bottom: -100,
              left: -70,
              child: AppTheme.glowCircle(color: AppColors.gold.withValues(alpha: 0.07), size: 320),
            ),
            Center(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(24),
                child: FadeTransition(
                  opacity: _fadeAnim,
                  child: SlideTransition(
                    position: _slideAnim,
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 420),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 36),
                        decoration: AppTheme.cardDecoration(),
                        child: Form(
                          key: _formKey,
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              ScaleTransition(
                                scale: _logoScaleAnim,
                                child: Container(
                                  width: 72,
                                  height: 72,
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    gradient: AppTheme.goldGradient,
                                    boxShadow: [
                                      BoxShadow(
                                        color: AppColors.gold.withValues(alpha: 0.35),
                                        blurRadius: 24,
                                        spreadRadius: 2,
                                      ),
                                    ],
                                  ),
                                  child: const Icon(
                                    Icons.lock_outline_rounded,
                                    color: AppColors.bgDarkTop,
                                    size: 32,
                                  ),
                                ),
                              ),
                              const SizedBox(height: 20),
                              ShaderMask(
                                shaderCallback: (bounds) => AppTheme.goldGradient.createShader(bounds),
                                child: const Text(
                                  'LOCUSTAF',
                                  style: TextStyle(
                                    fontSize: 30,
                                    fontWeight: FontWeight.bold,
                                    letterSpacing: 4,
                                    color: Colors.white,
                                  ),
                                ),
                              ),
                              const SizedBox(height: 8),
                              const Text(
                                'Sistema de control de asistencia',
                                style: AppTheme.bodyMd,
                              ),
                              const SizedBox(height: 36),
                              TextFormField(
                                controller: emailController,
                                keyboardType: TextInputType.emailAddress,
                                style: const TextStyle(color: AppColors.textWhite),
                                cursorColor: AppColors.gold,
                                decoration: AppTheme.inputDecoration(
                                  label: 'Correo electrónico',
                                  icon: Icons.email_outlined,
                                ),
                                validator: (value) {
                                  if (value == null || value.trim().isEmpty) {
                                    return 'Ingrese su correo electrónico';
                                  }
                                  final emailRegex = RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$');
                                  if (!emailRegex.hasMatch(value.trim())) {
                                    return 'Ingrese un correo electrónico válido';
                                  }
                                  return null;
                                },
                              ),
                              const SizedBox(height: 18),
                              TextFormField(
                                controller: passwordController,
                                obscureText: true,
                                style: const TextStyle(color: AppColors.textWhite),
                                cursorColor: AppColors.gold,
                                decoration: AppTheme.inputDecoration(
                                  label: 'Contraseña',
                                  icon: Icons.lock_outline_rounded,
                                ),
                                validator: (value) {
                                  if (value == null || value.isEmpty) {
                                    return 'Ingrese su contraseña';
                                  }
                                  return null;
                                },
                              ),
                              AnimatedSize(
                                duration: const Duration(milliseconds: 250),
                                curve: Curves.easeOut,
                                child: errorMessage != null
                                    ? Padding(
                                        padding: const EdgeInsets.only(top: 14),
                                        child: Container(
                                          width: double.infinity,
                                          padding: const EdgeInsets.all(12),
                                          decoration: BoxDecoration(
                                            color: AppColors.error.withValues(alpha: 0.12),
                                            borderRadius: BorderRadius.circular(AppTheme.radiusMd),
                                            border: Border.all(
                                              color: AppColors.error.withValues(alpha: 0.35),
                                            ),
                                          ),
                                          child: Row(
                                            children: [
                                              const Icon(Icons.error_outline_rounded, color: AppColors.error, size: 18),
                                              const SizedBox(width: 8),
                                              Expanded(
                                                child: Text(
                                                  errorMessage!,
                                                  style: const TextStyle(color: AppColors.error, fontSize: 13),
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                      )
                                    : const SizedBox(width: double.infinity),
                              ),
                              const SizedBox(height: 28),
                              SizedBox(
                                width: double.infinity,
                                height: 52,
                                child: AnimatedContainer(
                                  duration: const Duration(milliseconds: 200),
                                  decoration: BoxDecoration(
                                    borderRadius: BorderRadius.circular(AppTheme.radiusLg),
                                    gradient: LinearGradient(
                                      colors: isLoading
                                          ? [AppColors.gold.withValues(alpha: 0.4), AppColors.goldLight.withValues(alpha: 0.4)]
                                          : [AppColors.gold, AppColors.goldLight],
                                    ),
                                    boxShadow: isLoading
                                        ? []
                                        : [
                                            BoxShadow(
                                              color: AppColors.gold.withValues(alpha: 0.35),
                                              blurRadius: 18,
                                              offset: const Offset(0, 8),
                                            ),
                                          ],
                                  ),
                                  child: Material(
                                    color: Colors.transparent,
                                    child: InkWell(
                                      borderRadius: BorderRadius.circular(AppTheme.radiusLg),
                                      onTap: isLoading ? null : login,
                                      child: Center(
                                        child: isLoading
                                            ? const SizedBox(
                                                width: 22,
                                                height: 22,
                                                child: CircularProgressIndicator(
                                                  strokeWidth: 2,
                                                  color: AppColors.bgDarkTop,
                                                ),
                                              )
                                            : const Text(
                                                'Iniciar sesión',
                                                style: TextStyle(
                                                  fontSize: 16,
                                                  fontWeight: FontWeight.w700,
                                                  letterSpacing: 0.5,
                                                  color: AppColors.bgDarkTop,
                                                ),
                                              ),
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                              const SizedBox(height: 24),
                              Row(
                                children: [
                                  Expanded(child: Divider(color: AppColors.textMuted.withValues(alpha: 0.3))),
                                  Padding(
                                    padding: const EdgeInsets.symmetric(horizontal: 12),
                                    child: Text(
                                      '¿Sos nuevo?',
                                      style: TextStyle(
                                        color: AppColors.textMuted.withValues(alpha: 0.8),
                                        fontSize: 13,
                                      ),
                                    ),
                                  ),
                                  Expanded(child: Divider(color: AppColors.textMuted.withValues(alpha: 0.3))),
                                ],
                              ),
                              const SizedBox(height: 16),
                              SizedBox(
                                width: double.infinity,
                                height: 52,
                                child: OutlinedButton.icon(
                                  onPressed: isLoading ? null : loginWithGoogle,
                                  icon: const Icon(Icons.g_mobiledata, color: AppColors.textWhite, size: 26),
                                  label: const Text(
                                    'Crear cuenta con Google',
                                    style: TextStyle(
                                      fontSize: 15,
                                      fontWeight: FontWeight.w600,
                                      color: AppColors.textWhite,
                                    ),
                                  ),
                                  style: OutlinedButton.styleFrom(
                                    side: BorderSide(
                                      color: AppColors.gold.withValues(alpha: 0.5),
                                    ),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(AppTheme.radiusLg),
                                    ),
                                  ),
                                ),
                              ),
                              const SizedBox(height: 10),
                              Center(
                                child: Text(
                                  'Si ya tenés una cuenta, usá tu correo y contraseña.',
                                  style: TextStyle(
                                    color: AppColors.textMuted.withValues(alpha: 0.7),
                                    fontSize: 12,
                                  ),
                                  textAlign: TextAlign.center,
                                ),
                              ),
                            ],
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
    );
  }
}
