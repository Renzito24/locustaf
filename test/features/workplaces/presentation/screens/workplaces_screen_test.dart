import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:app_locustaf/core/models/user_model.dart';
import 'package:app_locustaf/features/authentication/presentation/providers/auth_provider.dart';
import 'package:app_locustaf/features/workplaces/data/models/workplace_model.dart';
import 'package:app_locustaf/features/workplaces/presentation/providers/workplace_notifier.dart';
import 'package:app_locustaf/features/workplaces/presentation/screens/workplaces_screen.dart';

void main() {
  group('WorkplacesScreen Tests', () {
    testWidgets('renders workplaces list', (tester) async {
      final workplace = WorkplaceModel(
        id: '123',
        companyId: 'company123',
        nombre: 'Main Office',
        latitud: -34.0,
        longitud: -58.0,
        radio: 100,
        isActive: true,
        direccion: 'Fake Street 123',
        description: 'Main headquarters',
        createdAt: DateTime.now(),
      );

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            userRoleProvider.overrideWith((ref) => UserRole.admin),
            workplacesStreamProvider.overrideWith((ref) => Stream.value([workplace])),
          ],
          child: const MaterialApp(
            home: Scaffold(
              body: WorkplacesScreen(),
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      expect(find.text('Lugares de trabajo'), findsOneWidget);
      expect(find.text('Nuevo lugar'), findsOneWidget); // Admin sees this
      expect(find.text('Main Office'), findsOneWidget);
      expect(find.text('Fake Street 123'), findsOneWidget);
      expect(find.text('Activo'), findsOneWidget);
    });
  });
}
