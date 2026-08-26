import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';

import 'package:app_locustaf/features/splash/presentation/screens/splash_screen.dart';

void main() {
  testWidgets('Splash screen renders LOCUSTAF', (WidgetTester tester) async {
    final router = GoRouter(
      initialLocation: '/',
      routes: [
        GoRoute(path: '/', builder: (_, _) => const SplashScreen()),
        GoRoute(path: '/login', builder: (_, _) => const Scaffold()),
      ],
    );

    await tester.pumpWidget(MaterialApp.router(routerConfig: router));

    expect(find.text('LOCUSTAF'), findsOneWidget);
    expect(find.byType(CircularProgressIndicator), findsOneWidget);

    // Avanza el timer de 2s del splash para que navegue a /login
    // y no quede un timer pendiente.
    await tester.pump(const Duration(seconds: 3));
  });
}
