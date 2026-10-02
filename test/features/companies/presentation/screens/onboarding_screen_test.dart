import 'package:app_locustaf/features/companies/presentation/screens/onboarding_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('OnboardingScreen renders form fields', (WidgetTester tester) async {
    await tester.pumpWidget(
      const ProviderScope(
        child: MaterialApp(
          home: OnboardingScreen(),
        ),
      ),
    );

    // Verify some fields exist
    expect(find.text('Completá tus datos y creá tu empresa'), findsOneWidget);
    expect(find.text('Nombre *'), findsOneWidget);
    expect(find.text('Apellido *'), findsOneWidget);
    expect(find.text('DNI *'), findsOneWidget);
    expect(find.text('Teléfono'), findsOneWidget);
    expect(find.text('Domicilio'), findsOneWidget);
    expect(find.text('Localidad *'), findsOneWidget);
    expect(find.text('Provincia *'), findsOneWidget);
    expect(find.text('Código postal *'), findsOneWidget);
    
    // Test validation
    await tester.ensureVisible(find.text('Crear mi empresa'));
    await tester.tap(find.text('Crear mi empresa'));
    await tester.pumpAndSettle();
    
    expect(find.text('Requerido'), findsWidgets);
    expect(find.text('Requerido para continuar.'), findsWidgets);
  });
}
