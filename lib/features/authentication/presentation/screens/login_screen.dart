import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/providers/firebase_providers.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/widgets/widgets.dart';
import '../providers/auth_provider.dart';
import '../../../../core/errors/error_handler.dart';
import '../widgets/forgot_password_dialog.dart';
import '../widgets/google_sign_in_section.dart';
import '../widgets/login_form_fields.dart';
import '../widgets/login_header_logo.dart';
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
  bool _obscurePassword = true;

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
      } else if (uri.queryParameters['company'] == 'inactive') {
        setState(() {
          errorMessage = 'Tu empresa está inactiva. Contactá al administrador.';
        });
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
    final authRepo = ref.read(authRepositoryProvider);
    await authRepo.logout();
    if (!mounted) return;
    setState(() {
      errorMessage = 'Tu cuenta ha sido desactivada o eliminada. Contactá al administrador.';
    });
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
    } catch (e) {
      // `catch (e)` y no `on Exception`: un Error/FlutterError de navegación
      // escapaba por completo y el usuario se quedaba sin ningún mensaje.
      debugPrint('LOGIN ERROR [${e.runtimeType}]: $e');
      if (!mounted) return;
      setState(() {
        errorMessage = ErrorHandler.parse(e).message;
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
          errorMessage = ErrorHandler.parse(e).message;
        });
      }
      // Si el correo ya existe con otro método (correo/contraseña), guiar al
      // usuario para que use el formulario o recupere su contraseña en lugar
      // de dejarlo en un estado confuso.
      if (e is FirebaseAuthException &&
          e.code == 'account-exists-with-different-credential') {
        _showAccountExistsDialog();
      }
    } finally {
      if (mounted) {
        setState(() {
          isLoading = false;
        });
      }
    }
  }

  Future<void> _showAccountExistsDialog() async {
    await showDialog<void>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        backgroundColor: AppColors.cardDark,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppTheme.radiusXl),
          side: BorderSide(color: AppColors.gold.withValues(alpha: 0.18)),
        ),
        title: const Text(
          'Ya existe una cuenta con este correo',
          style: TextStyle(color: AppColors.textWhite),
        ),
        content: const Text(
          'Este correo ya está registrado con correo y contraseña. Usá el formulario de arriba para iniciar sesión, o recuperá tu contraseña si no la recordás.',
          style: TextStyle(color: AppColors.textMuted, fontSize: 13),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(),
            child: const Text('Entendido',
                style: TextStyle(color: AppColors.gold)),
          ),
        ],
      ),
    );
  }

  Future<void> _showForgotPasswordDialog() async {
    final success = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => const ForgotPasswordDialog(),
    );
    if (success == true && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        AppTheme.successSnackBar(
          'Si el correo existe, te enviamos un enlace para restablecer tu contraseña.',
        ),
      );
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
                      child: AppCard(
                        padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 36),
                        child: Form(
                          key: _formKey,
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              LoginHeaderLogo(scaleAnim: _logoScaleAnim),
                              LoginEmailField(controller: emailController),
                              const SizedBox(height: 18),
                              LoginPasswordField(
                                controller: passwordController,
                                obscurePassword: _obscurePassword,
                                onToggleVisibility: () {
                                  setState(() {
                                    _obscurePassword = !_obscurePassword;
                                  });
                                },
                              ),
                              LoginErrorBox(errorMessage: errorMessage),
                              const SizedBox(height: 28),
                              LoginSubmitButton(
                                isLoading: isLoading,
                                onLogin: login,
                              ),
                              const SizedBox(height: 12),
                              Center(
                                child: TextButton(
                                  onPressed: isLoading
                                      ? null
                                      : _showForgotPasswordDialog,
                                  child: const Text(
                                    '¿Olvidaste tu contraseña?',
                                    style: TextStyle(
                                      color: AppColors.gold,
                                      fontSize: 13,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ),
                              ),
                              const SizedBox(height: 12),
                              GoogleSignInSection(
                                isLoading: isLoading,
                                onGoogleSignIn: loginWithGoogle,
                              ),
                              const SizedBox(height: 24),
                              const LoginFooter(),
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

