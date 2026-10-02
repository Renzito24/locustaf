import 'package:flutter/material.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/theme/app_theme.dart';

class LoginEmailField extends StatelessWidget {
  final TextEditingController controller;

  const LoginEmailField({
    super.key,
    required this.controller,
  });

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: controller,
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
    );
  }
}

class LoginPasswordField extends StatelessWidget {
  final TextEditingController controller;
  final bool obscurePassword;
  final VoidCallback onToggleVisibility;

  const LoginPasswordField({
    super.key,
    required this.controller,
    required this.obscurePassword,
    required this.onToggleVisibility,
  });

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: controller,
      obscureText: obscurePassword,
      style: const TextStyle(color: AppColors.textWhite),
      cursorColor: AppColors.gold,
      decoration: AppTheme.inputDecoration(
        label: 'Contraseña',
        icon: Icons.lock_outline_rounded,
      ).copyWith(
        suffixIcon: IconButton(
          icon: Icon(
            obscurePassword ? Icons.visibility : Icons.visibility_off,
            color: AppColors.textWhite.withValues(alpha: 0.6),
          ),
          onPressed: onToggleVisibility,
        ),
      ),
      validator: (value) {
        if (value == null || value.isEmpty) {
          return 'Ingrese su contraseña';
        }
        return null;
      },
    );
  }
}

class LoginErrorBox extends StatelessWidget {
  final String? errorMessage;

  const LoginErrorBox({
    super.key,
    required this.errorMessage,
  });

  @override
  Widget build(BuildContext context) {
    return AnimatedSize(
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
                    const Icon(Icons.error_outline_rounded,
                        color: AppColors.error, size: 18),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        errorMessage!,
                        style: const TextStyle(
                            color: AppColors.error, fontSize: 13),
                      ),
                    ),
                  ],
                ),
              ),
            )
          : const SizedBox(width: double.infinity),
    );
  }
}

class LoginSubmitButton extends StatelessWidget {
  final bool isLoading;
  final VoidCallback onLogin;

  const LoginSubmitButton({
    super.key,
    required this.isLoading,
    required this.onLogin,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: 52,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(AppTheme.radiusLg),
          gradient: LinearGradient(
            colors: isLoading
                ? [
                    AppColors.gold.withValues(alpha: 0.4),
                    AppColors.goldLight.withValues(alpha: 0.4)
                  ]
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
            onTap: isLoading ? null : onLogin,
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
    );
  }
}

class LoginFooter extends StatelessWidget {
  const LoginFooter({super.key});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Text(
        '© 2026 LOCUSTAF. Todos los derechos reservados.',
        style: TextStyle(
          color: AppColors.textMuted.withValues(alpha: 0.5),
          fontSize: 11,
        ),
      ),
    );
  }
}
