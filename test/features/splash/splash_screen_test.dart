import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:app_locustaf/features/authentication/presentation/providers/auth_provider.dart';
import 'package:app_locustaf/features/splash/presentation/screens/splash_screen.dart';

class _FakeSessionNotifier extends SessionNotifier {
  final SessionState _initial;
  bool retryCalled = false;
  bool signOutCalled = false;

  _FakeSessionNotifier(this._initial);

  @override
  SessionState build() {
    return _initial;
  }

  @override
  void retry() {
    retryCalled = true;
  }

  @override
  Future<void> signOut() async {
    signOutCalled = true;
  }
}

void main() {
  testWidgets('SplashScreen muestra CircularProgressIndicator mientras carga normalmente',
      (tester) async {
    final notifier = _FakeSessionNotifier(
      const SessionState(
        isLoading: true,
        hasProfileError: false,
      ),
    );

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          sessionProvider.overrideWith(() => notifier),
        ],
        child: const MaterialApp(
          home: SplashScreen(),
        ),
      ),
    );

    expect(find.text('LOCUSTAF'), findsOneWidget);
    expect(find.byType(CircularProgressIndicator), findsOneWidget);
    expect(find.text('No se pudo cargar la sesión'), findsNothing);
  });

  testWidgets(
      'SplashScreen muestra mensaje de error, botón de reintento y botón de cerrar sesión',
      (tester) async {
    final notifier = _FakeSessionNotifier(
      const SessionState(
        isLoading: false,
        hasProfileError: true,
        profileError: 'No se pudo conectar con el servidor. Verifique su conexión a internet.',
      ),
    );

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          sessionProvider.overrideWith(() => notifier),
        ],
        child: const MaterialApp(
          home: SplashScreen(),
        ),
      ),
    );

    expect(find.text('No se pudo cargar la sesión'), findsOneWidget);
    expect(
      find.text('No se pudo conectar con el servidor. Verifique su conexión a internet.'),
      findsOneWidget,
    );
    expect(find.byKey(const Key('splash_retry_button')), findsOneWidget);
    expect(find.byKey(const Key('splash_sign_out_button')), findsOneWidget);

    // Probar click en Reintentar
    await tester.tap(find.byKey(const Key('splash_retry_button')));
    await tester.pump();
    expect(notifier.retryCalled, isTrue);

    // Probar click en Cerrar sesión
    await tester.tap(find.byKey(const Key('splash_sign_out_button')));
    await tester.pump();
    expect(notifier.signOutCalled, isTrue);
  });
}
