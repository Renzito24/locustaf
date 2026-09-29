import 'package:app_locustaf/core/router/app_routes.dart';
import 'package:app_locustaf/features/authentication/domain/repositories/auth_repository.dart';
import 'package:app_locustaf/features/authentication/presentation/providers/auth_provider.dart';
import 'package:app_locustaf/features/authentication/presentation/screens/login_screen.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';

/// Fake del [AuthRepository] que no construye `UserCredential` (imposible
/// fuera de firebase_auth): los caminos exitosos reales quedan cubiertos por
/// la lógica de `resolveRedirect` (test de guards) + el flujo server-side de
/// las callables (functions integration tests).
class _FakeAuthRepository implements AuthRepository {
  Object? loginError;
  Object? googleError;
  Object? resetPasswordError;
  int resetPasswordCalls = 0;
  bool loggedOut = false;

  @override
  Future<UserCredential> login(String email, String password) async {
    if (loginError != null) throw loginError!;
    throw StateError('El path de éxito requiere firebase_auth real');
  }

  @override
  Future<UserCredential?> loginWithGoogle() async {
    if (googleError != null) throw googleError!;
    return null; // usuario canceló el popup de Google
  }

  @override
  Future<void> logout() async {
    loggedOut = true;
  }

  @override
  User? getCurrentUser() => null;

  @override
  Stream<User?> authStateChanges() => const Stream.empty();

  @override
  Future<void> sendPasswordReset(String email) async {
    resetPasswordCalls++;
    if (resetPasswordError != null) throw resetPasswordError!;
  }

  @override
  Future<void> linkPassword({
    required String email,
    required String password,
  }) async {}
}

void main() {
  late _FakeAuthRepository authRepo;
  late GoRouter router;

  Future<void> pumpLogin(
    WidgetTester tester, {
    String initialLocation = '/login',
  }) async {
    router = GoRouter(
      initialLocation: initialLocation,
      routes: [
        GoRoute(
          path: '/login',
          builder: (context, state) => const LoginScreen(),
        ),
        GoRoute(
          path: RoutePaths.dashboard,
          builder: (context, state) => const Scaffold(
            body: Center(child: Text('Dashboard automarker', key: ValueKey('dashboard'))),
          ),
        ),
      ],
    );

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          authRepositoryProvider.overrideWithValue(authRepo),
        ],
        child: MaterialApp.router(
          routerConfig: router,
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  setUp(() {
    authRepo = _FakeAuthRepository();
  });

  Future<void> loginConCredencialesValidas(WidgetTester tester) async {
    await tester.enterText(find.byType(TextFormField).first, 'juan@empresa.com');
    await tester.enterText(find.byType(TextFormField).last, 'secret-password');
    await tester.tap(find.text('Iniciar sesión'));
    await tester.pumpAndSettle();
  }

  group('LoginScreen E2E — validaciones', () {
    testWidgets('emails inválidos: no llama al repo y muestra error', (tester) async {
      await pumpLogin(tester);
      await tester.enterText(find.byType(TextFormField).first, 'correo-invalido');
      await tester.enterText(find.byType(TextFormField).last, 'secreto123');
      await tester.tap(find.text('Iniciar sesión'));
      await tester.pumpAndSettle();

      expect(find.text('Ingrese un correo electrónico válido'), findsOneWidget);
      expect(authRepo.loginError, isNull); // sin llamada al backend
    });

    testWidgets('campos vacíos: muestra errores de requeridos', (tester) async {
      await pumpLogin(tester);
      await tester.tap(find.text('Iniciar sesión'));
      await tester.pumpAndSettle();
      expect(find.text('Ingrese su correo electrónico'), findsOneWidget);
      expect(find.text('Ingrese su contraseña'), findsOneWidget);
    });

    testWidgets('visibilidad de contraseña: el botón alterna entre ocultar y mostrar', (tester) async {
      await pumpLogin(tester);
      final passwordField = find.byType(TextFormField).last;

      // Por defecto la contraseña está oculta y se muestra el icono visibility
      TextField textField = tester.widget<TextField>(find.descendant(of: passwordField, matching: find.byType(TextField)));
      expect(textField.obscureText, isTrue);
      expect(find.byIcon(Icons.visibility), findsOneWidget);
      expect(find.byIcon(Icons.visibility_off), findsNothing);

      // Tocar el icono para mostrar la contraseña
      await tester.tap(find.byIcon(Icons.visibility));
      await tester.pumpAndSettle();

      textField = tester.widget<TextField>(find.descendant(of: passwordField, matching: find.byType(TextField)));
      expect(textField.obscureText, isFalse);
      expect(find.byIcon(Icons.visibility_off), findsOneWidget);
      expect(find.byIcon(Icons.visibility), findsNothing);

      // Tocar de nuevo para volver a ocultar
      await tester.tap(find.byIcon(Icons.visibility_off));
      await tester.pumpAndSettle();

      textField = tester.widget<TextField>(find.descendant(of: passwordField, matching: find.byType(TextField)));
      expect(textField.obscureText, isTrue);
      expect(find.byIcon(Icons.visibility), findsOneWidget);
      expect(find.byIcon(Icons.visibility_off), findsNothing);
    });
  });

  group('LoginScreen E2E — mapeo de errores', () {
    testWidgets('user-not-found: mensaje de cuenta inexistente/credenciales incorrectas', (tester) async {
      authRepo.loginError = FirebaseAuthException(code: 'user-not-found');
      await pumpLogin(tester);
      await loginConCredencialesValidas(tester);
      expect(find.text('El correo o la contraseña no son correctos.'), findsOneWidget);
      expect(find.byKey(const ValueKey('dashboard')), findsNothing);
    });

    testWidgets('wrong-password: mensaje de credenciales incorrectas', (tester) async {
      authRepo.loginError = FirebaseAuthException(code: 'wrong-password');
      await pumpLogin(tester);
      await loginConCredencialesValidas(tester);
      expect(find.text('El correo o la contraseña no son correctos.'), findsOneWidget);
    });

    testWidgets('user-disabled: mensaje de cuenta deshabilitada', (tester) async {
      authRepo.loginError = FirebaseAuthException(code: 'user-disabled');
      await pumpLogin(tester);
      await loginConCredencialesValidas(tester);
      expect(find.text('Tu cuenta se encuentra deshabilitada.'), findsOneWidget);
    });

    testWidgets('invalid-credential: mensaje genérico de credenciales', (tester) async {
      authRepo.loginError = FirebaseAuthException(code: 'invalid-credential');
      await pumpLogin(tester);
      await loginConCredencialesValidas(tester);
      expect(find.text('El correo o la contraseña no son correctos.'), findsOneWidget);
    });

    testWidgets('error genérico (Exception): mensaje de error inesperado', (tester) async {
      authRepo.loginError = Exception('boom');
      await pumpLogin(tester);
      await loginConCredencialesValidas(tester);
      expect(find.textContaining('Se produjo un problema inesperado'), findsOneWidget);
    });

    testWidgets('FirebaseException: muestra mensaje de problema inesperado o conexión', (tester) async {
      authRepo.loginError = FirebaseException(
        plugin: 'cloud_firestore',
        code: 'unavailable',
        message: 'Network error.',
      );
      await pumpLogin(tester);
      await loginConCredencialesValidas(tester);
      expect(
        find.textContaining('Problemas de conexión'),
        findsOneWidget,
      );
    });

    testWidgets('PlatformException: muestra mensaje amigable del sistema',
        (tester) async {
      authRepo.loginError = PlatformException(code: 'DEVELOPER_ERROR');
      await pumpLogin(tester);
      await loginConCredencialesValidas(tester);
      expect(find.textContaining('Ocurrió un error en el dispositivo'), findsOneWidget);
    });

    testWidgets('FlutterError: muestra mensaje genérico', (tester) async {
      authRepo.loginError = FlutterError('GoRouter context deactivated');
      await pumpLogin(tester);
      await loginConCredencialesValidas(tester);
      expect(find.textContaining('Se produjo un problema inesperado'), findsOneWidget);
    });

    testWidgets('FirebaseAuthException con code no mapeado: muestra mensaje genérico de autenticación',
        (tester) async {
      authRepo.loginError = FirebaseAuthException(code: 'internal-error');
      await pumpLogin(tester);
      await loginConCredencialesValidas(tester);
      expect(find.textContaining('Ocurrió un problema al iniciar sesión'), findsOneWidget);
    });
  });

  group('LoginScreen E2E — Google', () {
    testWidgets('cancelación de Google: no navega ni muestra error', (tester) async {
      await pumpLogin(tester);
      await tester.ensureVisible(find.text('Iniciar sesión con Google'));
      await tester.tap(find.text('Iniciar sesión con Google'));
      await tester.pumpAndSettle();
      expect(find.byKey(const ValueKey('dashboard')), findsNothing);
      expect(find.text('Error inesperado. Intente nuevamente.'), findsNothing);
    });

    testWidgets('popup-cerrado: mensaje de cancelación', (tester) async {
      authRepo.googleError = FirebaseAuthException(code: 'popup-closed-by-user');
      await pumpLogin(tester);
      await tester.ensureVisible(find.text('Iniciar sesión con Google'));
      await tester.tap(find.text('Iniciar sesión con Google'));
      await tester.pumpAndSettle();
      expect(find.text('Inicio de sesión cancelado'), findsOneWidget);
    });
  });

  group('LoginScreen E2E — rutas de bloqueo', () {
    testWidgets('cuenta bloqueada (?blocked=true): fuerza logout y muestra mensaje', (tester) async {
      await pumpLogin(tester, initialLocation: '/login?blocked=true');
      await tester.pumpAndSettle();
      expect(authRepo.loggedOut, isTrue, reason: 'debe cerrar sesión del usuario bloqueado');
      expect(find.textContaining('desactivada o eliminada'), findsOneWidget);
    });
  });

  group('LoginScreen E2E — recuperación de contraseña', () {
    Future<void> abrirDialogoRecuperacion(WidgetTester tester) async {
      await tester.tap(find.text('¿Olvidaste tu contraseña?'));
      await tester.pumpAndSettle();
      expect(find.text('Recuperar contraseña'), findsOneWidget);
    }

    Future<void> enviarRecuperacion(
      WidgetTester tester, {
      required String email,
    }) async {
      await tester.enterText(
        find.descendant(
          of: find.byType(AlertDialog),
          matching: find.byType(TextFormField),
        ),
        email,
      );
      await tester.tap(find.text('Enviar enlace'));
      await tester.pumpAndSettle();
    }

    testWidgets('email válido: envía el enlace, cierra el diálogo y muestra éxito (sin assertion del framework)', (tester) async {
      await pumpLogin(tester);
      await abrirDialogoRecuperacion(tester);
      await enviarRecuperacion(tester, email: 'juan@empresa.com');

      expect(authRepo.resetPasswordCalls, 1);
      expect(find.text('Recuperar contraseña'), findsNothing, reason: 'el diálogo debe cerrarse');
      expect(
        find.textContaining('te enviamos un enlace'),
        findsOneWidget,
        reason: 'SnackBar de éxito tras el pop del diálogo',
      );
    });

    testWidgets('correo no registrado: muestra el error del backend y mantiene el diálogo abierto', (tester) async {
      authRepo.resetPasswordError = FirebaseAuthException(code: 'user-not-found');
      await pumpLogin(tester);
      await abrirDialogoRecuperacion(tester);
      await enviarRecuperacion(tester, email: 'inexistente@empresa.com');

      expect(authRepo.resetPasswordCalls, 1);
      expect(find.textContaining('El correo o la contraseña no son correctos.'), findsOneWidget);
      expect(find.text('Recuperar contraseña'), findsOneWidget, reason: 'el diálogo sigue abierto');
    });

    testWidgets('email inválido: no llama al backend y muestra error de validación', (tester) async {
      await pumpLogin(tester);
      await abrirDialogoRecuperacion(tester);
      await enviarRecuperacion(tester, email: 'correo-invalido');

      expect(authRepo.resetPasswordCalls, 0);
      expect(find.text('Ingrese un correo electrónico válido'), findsOneWidget);
    });
  });
}