class Validators {
  Validators._();

  static String? required(String? value, String fieldName) {
    if (value == null || value.trim().isEmpty) {
      return '$fieldName es obligatorio';
    }
    return null;
  }

  static String? email(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'El correo electrónico es obligatorio';
    }
    final emailRegex = RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$');
    if (!emailRegex.hasMatch(value.trim())) {
      return 'Ingrese un correo electrónico válido';
    }
    return null;
  }

  static String? password(String? value) {
    if (value == null || value.isEmpty) {
      return 'La contraseña es obligatoria';
    }
    if (value.length < 6) {
      return 'La contraseña debe tener al menos 6 caracteres';
    }
    return null;
  }

  static String? dni(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'El DNI es obligatorio';
    }
    return null;
  }

  /// Valida un CUIT argentino (11 dígitos) incluyendo el dígito verificador.
  static String? cuit(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'El CUIT es obligatorio';
    }
    final digits = value.replaceAll(RegExp(r'[^0-9]'), '');
    if (digits.length != 11) {
      return 'El CUIT debe tener 11 dígitos';
    }
    const weights = [5, 4, 3, 2, 7, 6, 5, 4, 3, 2];
    var sum = 0;
    for (var i = 0; i < 10; i++) {
      sum += int.parse(digits[i]) * weights[i];
    }
    final check = (11 - (sum % 11)) % 11;
    final expected = check == 11 ? 0 : check;
    if (int.parse(digits[10]) != expected) {
      return 'El CUIT no es válido';
    }
    return null;
  }

  /// Valida que una latitud esté en el rango válido [-90, 90].
  static String? latitud(double? value) {
    if (value == null) return 'La latitud es obligatoria';
    if (value < -90 || value > 90) {
      return 'La latitud debe estar entre -90 y 90';
    }
    return null;
  }

  /// Valida que una longitud esté en el rango válido [-180, 180].
  static String? longitud(double? value) {
    if (value == null) return 'La longitud es obligatoria';
    if (value < -180 || value > 180) {
      return 'La longitud debe estar entre -180 y 180';
    }
    return null;
  }
}