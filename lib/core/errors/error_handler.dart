import 'dart:developer';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:flutter/services.dart';

import 'app_error.dart';
import 'domain_exceptions.dart';

class ErrorHandler {
  static AppError parse(Object error) {
    _logError(error);

    // 1. Excepciones de dominio
    if (error is DomainException) {
      if (error is LocationOutOfRangeException) {
        return const AppError(
          title: 'Fuera del área de trabajo',
          message: 'Para registrar tu ingreso, tenés que encontrarte dentro del área habilitada de tu lugar de trabajo.',
          type: AppErrorType.functional,
        );
      }
      if (error is LocationAccuracyException) {
        return const AppError(
          title: 'Señal de ubicación débil',
          message: 'No podemos determinar tu ubicación con suficiente precisión. Acercate a una ventana o salí al exterior unos segundos.',
          type: AppErrorType.functional,
        );
      }
      if (error is LocationDisabledException) {
        return const AppError(
          title: 'Ubicación desactivada',
          message: 'Activá la ubicación de tu dispositivo para poder registrar tu asistencia.',
          type: AppErrorType.functional,
        );
      }
      if (error is LocationPermissionException) {
        return const AppError(
          title: 'Permiso de ubicación necesario',
          message: 'LOCUSTAF necesita acceder a tu ubicación para verificar que estés en tu lugar de trabajo.',
          type: AppErrorType.permission,
        );
      }
      if (error is FileSizeException) {
        return const AppError(
          title: 'Archivo demasiado grande',
          message: 'El archivo es demasiado grande. El límite máximo es de 10 MB.',
          type: AppErrorType.functional,
        );
      }
      if (error is FileFormatException) {
        return const AppError(
          title: 'Formato no permitido',
          message: 'El formato del archivo no está permitido. Seleccioná un PDF o un formato admitido.',
          type: AppErrorType.functional,
        );
      }
      return AppError(
        title: 'Atención',
        message: error.message,
        type: AppErrorType.functional,
      );
    }

    // 2. FirebaseAuthException
    if (error is FirebaseAuthException) {
      String message;
      switch (error.code) {
        case 'invalid-credential':
        case 'wrong-password':
        case 'user-not-found':
          message = 'El correo o la contraseña no son correctos.';
          break;
        case 'user-disabled':
          message = 'Tu cuenta se encuentra deshabilitada.';
          break;
        case 'too-many-requests':
          message = 'Demasiados intentos fallidos. Por favor, intentá más tarde.';
          break;
        case 'network-request-failed':
          return const AppError(
            title: 'Sin conexión',
            message: 'No pudimos conectarnos. Revisá tu conexión e intentá nuevamente.',
            type: AppErrorType.recoverable,
          );
        case 'popup-closed-by-user':
          return const AppError(
            title: 'Atención',
            message: 'Inicio de sesión cancelado',
            type: AppErrorType.functional,
          );
        default:
          message = 'Ocurrió un problema al iniciar sesión. Por favor, verificá tu conexión y volvé a intentarlo.';
      }
      return AppError(
        title: 'Error de autenticación',
        message: message,
        type: AppErrorType.functional,
      );
    }

    // 3. FirebaseFunctionsException
    if (error is FirebaseFunctionsException) {
      switch (error.code) {
        case 'unavailable':
        case 'deadline-exceeded':
          return const AppError(
            title: 'Sin conexión',
            message: 'No se pudo conectar con el servidor. Revisá tu conexión a internet e intentá de nuevo.',
            type: AppErrorType.recoverable,
          );
        case 'unauthenticated':
        case 'permission-denied':
          return const AppError(
            title: 'Acceso denegado',
            message: 'No tenés los permisos necesarios para realizar esta acción.',
            type: AppErrorType.permission,
          );
        case 'internal':
          return const AppError(
            title: 'Error del servidor',
            message: 'Ocurrió un problema inesperado en el servidor. Intentá nuevamente más tarde.',
            type: AppErrorType.unexpected,
          );
        case 'failed-precondition':
        case 'invalid-argument':
        case 'resource-exhausted':
        case 'not-found':
          return AppError(
            title: 'Atención',
            message: error.message ?? 'No se pudo completar la operación.',
            type: AppErrorType.functional,
          );
        default:
          return const AppError(
            title: 'Atención',
            message: 'Ocurrió un problema inesperado.',
            type: AppErrorType.unexpected,
          );
      }
    }

    // 4. FirebaseException (Firestore/Storage y genéricos)
    if (error is FirebaseException) {
      switch (error.code) {
        case 'permission-denied':
          return const AppError(
            title: 'Acceso denegado',
            message: 'No tenés los permisos necesarios para realizar esta acción.',
            type: AppErrorType.permission,
          );
        case 'unavailable':
          return const AppError(
            title: 'Sin conexión',
            message: 'Problemas de conexión con el servidor. Reintentando...',
            type: AppErrorType.recoverable,
          );
        default:
          return const AppError(
            title: 'Problema inesperado',
            message: 'Se produjo un problema inesperado. Intentá nuevamente.',
            type: AppErrorType.unexpected,
          );
      }
    }

    // 5. PlatformException
    if (error is PlatformException) {
      return const AppError(
        title: 'Error del sistema',
        message: 'Ocurrió un error en el dispositivo. Intentá nuevamente.',
        type: AppErrorType.unexpected,
      );
    }

    // 6. Error genérico
    return const AppError(
      title: 'Problema inesperado',
      message: 'Se produjo un problema inesperado. Intentá nuevamente.',
      type: AppErrorType.unexpected,
    );
  }

  static void _logError(Object error) {
    if (error is FirebaseAuthException) {
      log('ErrorHandler caught: FirebaseAuthException [${error.code}]', name: 'ErrorHandler');
    } else if (error is FirebaseFunctionsException) {
      log('ErrorHandler caught: FirebaseFunctionsException [${error.code}]', name: 'ErrorHandler');
    } else if (error is FirebaseException) {
      log('ErrorHandler caught: FirebaseException [${error.code}]', name: 'ErrorHandler');
    } else if (error is PlatformException) {
      log('ErrorHandler caught: PlatformException [${error.code}]', name: 'ErrorHandler');
    } else if (error is DomainException) {
      log('ErrorHandler caught: ${error.runtimeType}', name: 'ErrorHandler');
    } else {
      log('ErrorHandler caught: ${error.runtimeType}', name: 'ErrorHandler');
    }
  }
}
