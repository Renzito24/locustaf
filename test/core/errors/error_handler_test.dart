import 'package:flutter_test/flutter_test.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:flutter/services.dart';
import 'package:app_locustaf/core/errors/app_error.dart';
import 'package:app_locustaf/core/errors/domain_exceptions.dart';
import 'package:app_locustaf/core/errors/error_handler.dart';

void main() {
  group('ErrorHandler Tests', () {
    test('parsea LocationOutOfRangeException correctamente', () {
      final error = LocationOutOfRangeException('detalles extra');
      final appError = ErrorHandler.parse(error);

      expect(appError.type, AppErrorType.functional);
      expect(appError.title, 'Fuera del área de trabajo');
      expect(appError.message, 'Para registrar tu ingreso, tenés que encontrarte dentro del área habilitada de tu lugar de trabajo.');
    });

    test('parsea FirebaseAuthException conocido (invalid-credential)', () {
      final error = FirebaseAuthException(code: 'invalid-credential');
      final appError = ErrorHandler.parse(error);

      expect(appError.type, AppErrorType.functional);
      expect(appError.title, 'Error de autenticación');
      expect(appError.message, 'El correo o la contraseña no son correctos.');
    });

    test('parsea FirebaseAuthException desconocido', () {
      final error = FirebaseAuthException(code: 'unknown-code-xyz');
      final appError = ErrorHandler.parse(error);

      expect(appError.type, AppErrorType.functional);
      expect(appError.message, 'Ocurrió un problema al iniciar sesión. Por favor, verificá tu conexión y volvé a intentarlo.');
    });

    test('parsea FirebaseFunctionsException funcional (failed-precondition)', () {
      final error = FirebaseFunctionsException(
        code: 'failed-precondition',
        message: 'No se puede registrar asistencia sin estar activo.',
      );
      final appError = ErrorHandler.parse(error);

      expect(appError.type, AppErrorType.functional);
      expect(appError.title, 'Atención');
      expect(appError.message, 'No se puede registrar asistencia sin estar activo.');
    });

    test('parsea FirebaseFunctionsException de red (unavailable)', () {
      final error = FirebaseFunctionsException(code: 'unavailable', message: 'test');
      final appError = ErrorHandler.parse(error);

      expect(appError.type, AppErrorType.recoverable);
      expect(appError.title, 'Sin conexión');
      expect(appError.message, 'No se pudo conectar con el servidor. Revisá tu conexión a internet e intentá de nuevo.');
    });

    test('parsea FirebaseException (permission-denied)', () {
      final error = FirebaseException(plugin: 'firestore', code: 'permission-denied');
      final appError = ErrorHandler.parse(error);

      expect(appError.type, AppErrorType.permission);
      expect(appError.title, 'Acceso denegado');
      expect(appError.message, 'No tenés los permisos necesarios para realizar esta acción.');
    });

    test('parsea PlatformException genérica', () {
      final error = PlatformException(code: 'ERROR_PLATFORM');
      final appError = ErrorHandler.parse(error);

      expect(appError.type, AppErrorType.unexpected);
      expect(appError.title, 'Error del sistema');
    });

    test('parsea error genérico', () {
      final error = Exception('Algo explotó');
      final appError = ErrorHandler.parse(error);

      expect(appError.type, AppErrorType.unexpected);
      expect(appError.message, 'Se produjo un problema inesperado. Intentá nuevamente.');
    });
  });
}
