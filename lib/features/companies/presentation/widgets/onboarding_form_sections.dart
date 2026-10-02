import 'package:flutter/material.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/theme/app_theme.dart';

class OnboardingPersonalDataSection extends StatelessWidget {
  final TextEditingController nombreController;
  final TextEditingController apellidoController;
  final TextEditingController dniController;
  final TextEditingController telefonoController;
  final TextEditingController direccionController;
  final TextEditingController localidadController;
  final TextEditingController provinciaController;
  final TextEditingController codigoPostalController;

  const OnboardingPersonalDataSection({
    super.key,
    required this.nombreController,
    required this.apellidoController,
    required this.dniController,
    required this.telefonoController,
    required this.direccionController,
    required this.localidadController,
    required this.provinciaController,
    required this.codigoPostalController,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Datos personales', style: AppTheme.headingMd),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: TextFormField(
                controller: nombreController,
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
                controller: apellidoController,
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
          controller: dniController,
          keyboardType: TextInputType.number,
          style: const TextStyle(color: AppColors.textWhite),
          decoration: AppTheme.inputDecoration(
            label: 'DNI *',
            icon: Icons.badge_outlined,
          ),
          validator: (v) => (v == null || v.trim().isEmpty) ? 'Requerido' : null,
        ),
        const SizedBox(height: 12),
        TextFormField(
          controller: telefonoController,
          keyboardType: TextInputType.phone,
          style: const TextStyle(color: AppColors.textWhite),
          decoration: AppTheme.inputDecoration(
            label: 'Teléfono',
            icon: Icons.phone_outlined,
          ),
        ),
        const SizedBox(height: 12),
        TextFormField(
          controller: direccionController,
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
                controller: localidadController,
                style: const TextStyle(color: AppColors.textWhite),
                decoration: AppTheme.inputDecoration(
                  label: 'Localidad *',
                  icon: Icons.location_city_outlined,
                ),
                validator: (v) =>
                    (v == null || v.trim().isEmpty) ? 'Requerido' : null,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: TextFormField(
                controller: provinciaController,
                style: const TextStyle(color: AppColors.textWhite),
                decoration: AppTheme.inputDecoration(
                  label: 'Provincia *',
                  icon: Icons.map_outlined,
                ),
                validator: (v) =>
                    (v == null || v.trim().isEmpty) ? 'Requerido' : null,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        TextFormField(
          controller: codigoPostalController,
          keyboardType: TextInputType.number,
          style: const TextStyle(color: AppColors.textWhite),
          decoration: AppTheme.inputDecoration(
            label: 'Código postal *',
            icon: Icons.numbers_outlined,
          ),
          validator: (v) => (v == null || v.trim().isEmpty) ? 'Requerido' : null,
        ),
      ],
    );
  }
}

class OnboardingCredentialsSection extends StatelessWidget {
  final TextEditingController passwordController;
  final TextEditingController confirmPasswordController;

  const OnboardingCredentialsSection({
    super.key,
    required this.passwordController,
    required this.confirmPasswordController,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Credenciales de acceso', style: AppTheme.headingMd),
        const SizedBox(height: 4),
        Text(
          'Elegí una contraseña para poder ingresar con tu correo y contraseña.',
          style: AppTheme.bodyMd,
        ),
        const SizedBox(height: 12),
        TextFormField(
          controller: passwordController,
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
          controller: confirmPasswordController,
          obscureText: true,
          style: const TextStyle(color: AppColors.textWhite),
          decoration: AppTheme.inputDecoration(
            label: 'Confirmar contraseña *',
            icon: Icons.lock_outline,
          ),
          validator: (v) {
            if (v == null || v.isEmpty) return 'Requerido';
            if (v != passwordController.text) {
              return 'Las contraseñas no coinciden';
            }
            return null;
          },
        ),
      ],
    );
  }
}

class OnboardingCompanyDataSection extends StatelessWidget {
  final TextEditingController empresaController;
  final TextEditingController razonSocialController;
  final TextEditingController cuitController;
  final TextEditingController empresaEmailController;

  const OnboardingCompanyDataSection({
    super.key,
    required this.empresaController,
    required this.razonSocialController,
    required this.cuitController,
    required this.empresaEmailController,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Datos de la empresa', style: AppTheme.headingMd),
        const SizedBox(height: 12),
        TextFormField(
          controller: empresaController,
          style: const TextStyle(color: AppColors.textWhite),
          decoration: AppTheme.inputDecoration(
            label: 'Nombre comercial *',
            icon: Icons.business_outlined,
          ),
          validator: (v) => (v == null || v.trim().isEmpty) ? 'Requerido' : null,
        ),
        const SizedBox(height: 12),
        TextFormField(
          controller: razonSocialController,
          style: const TextStyle(color: AppColors.textWhite),
          decoration: AppTheme.inputDecoration(
            label: 'Razón social *',
            icon: Icons.business_outlined,
          ),
          validator: (v) => (v == null || v.trim().isEmpty) ? 'Requerido' : null,
        ),
        const SizedBox(height: 12),
        TextFormField(
          controller: cuitController,
          style: const TextStyle(color: AppColors.textWhite),
          decoration: AppTheme.inputDecoration(
            label: 'CUIT *',
            icon: Icons.numbers_outlined,
          ),
          validator: (v) => (v == null || v.trim().isEmpty) ? 'Requerido' : null,
        ),
        const SizedBox(height: 12),
        TextFormField(
          controller: empresaEmailController,
          style: const TextStyle(color: AppColors.textWhite),
          decoration: AppTheme.inputDecoration(
            label: 'Email de la empresa',
            icon: Icons.email_outlined,
          ),
        ),
      ],
    );
  }
}

class OnboardingLegalSection extends StatelessWidget {
  final bool aceptaTerminos;
  final bool aceptaPrivacidad;
  final bool isLoading;
  final Function(bool) onTerminosChanged;
  final Function(bool) onPrivacidadChanged;
  final Function(String, String) onShowDocument;

  const OnboardingLegalSection({
    super.key,
    required this.aceptaTerminos,
    required this.aceptaPrivacidad,
    required this.isLoading,
    required this.onTerminosChanged,
    required this.onPrivacidadChanged,
    required this.onShowDocument,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
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
          initialValue: aceptaTerminos,
          validator: (v) => (v == true) ? null : 'Requerido para continuar.',
          builder: (field) => Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Checkbox(
                    value: aceptaTerminos,
                    activeColor: AppColors.gold,
                    checkColor: Colors.white,
                    side: const BorderSide(color: AppColors.textSecondary),
                    onChanged: isLoading
                        ? null
                        : (v) {
                            onTerminosChanged(v ?? false);
                            field.didChange(v ?? false);
                          },
                  ),
                  Expanded(
                    child: GestureDetector(
                      onTap: () => onShowDocument(
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
          initialValue: aceptaPrivacidad,
          validator: (v) => (v == true) ? null : 'Requerido para continuar.',
          builder: (field) => Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Checkbox(
                    value: aceptaPrivacidad,
                    activeColor: AppColors.gold,
                    checkColor: Colors.white,
                    side: const BorderSide(color: AppColors.textSecondary),
                    onChanged: isLoading
                        ? null
                        : (v) {
                            onPrivacidadChanged(v ?? false);
                            field.didChange(v ?? false);
                          },
                  ),
                  Expanded(
                    child: GestureDetector(
                      onTap: () => onShowDocument(
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
      ],
    );
  }
}
