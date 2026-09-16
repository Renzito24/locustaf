import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:app_locustaf/core/models/user_model.dart';
import 'package:app_locustaf/core/providers/data_providers.dart';
import 'package:app_locustaf/features/authentication/presentation/providers/auth_provider.dart';
import 'package:app_locustaf/features/employees/domain/repositories/users_repository.dart';
import 'package:app_locustaf/features/employees/presentation/providers/users_provider.dart';
import 'package:app_locustaf/features/employees/presentation/screens/create_employee_screen.dart';
import 'package:app_locustaf/features/workplaces/data/models/workplace_model.dart';
import 'package:app_locustaf/features/workplaces/presentation/providers/workplace_notifier.dart';

/// Fase B — Corrección: la pantalla "Nuevo usuario" no debe emitir
/// "Usuario creado correctamente" al abrirse (regresión del falso éxito) y el
/// crear con fallo debe mostrar error en vez de éxito.
class FakeUsersRepository implements UsersRepository {
  FakeUsersRepository({this.fail = false});

  final bool fail;

  @override
  Stream<List<UserModel>> getUsers() => const Stream.empty();

  @override
  Future<void> createUser(UserModel user, String password) async {
    if (fail) throw Exception('fallo simulado');
  }

  @override
  Future<void> updateUser(UserModel user) async {}

  @override
  Future<void> deleteUser(String uid) async {}
}

void main() {
  const companyId = 'company-1';

  Future<void> pumpScreen(
    WidgetTester tester, {
    FakeUsersRepository? repository,
  }) async {
    tester.view.physicalSize = const Size(900, 2200);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          usersStreamProvider.overrideWith(
            (ref) => Stream.value(<UserModel>[]),
          ),
          activeWorkplacesProvider.overrideWith(
            (ref) => const AsyncValue.data(<WorkplaceModel>[]),
          ),
          userRoleProvider.overrideWithValue(UserRole.admin),
          currentCompanyIdProvider.overrideWithValue(companyId),
          if (repository != null)
            usersRepositoryProvider.overrideWithValue(repository),
        ],
        child: const MaterialApp(home: Scaffold(body: CreateEmployeeScreen())),
      ),
    );
    await tester.pumpAndSettle();
  }

  Future<void> fillAndSubmit(WidgetTester tester) async {
    await tester.enterText(
      find.widgetWithText(TextFormField, 'Nombre *'),
      'Carlos',
    );
    await tester.enterText(
      find.widgetWithText(TextFormField, 'Apellido *'),
      'Gómez',
    );
    await tester.enterText(
      find.widgetWithText(TextFormField, 'Correo electrónico *'),
      'carlos@test.com',
    );
    await tester.enterText(
      find.widgetWithText(TextFormField, 'DNI *'),
      '11222333',
    );
    await tester.enterText(
      find.widgetWithText(TextFormField, 'Contraseña *'),
      '123456',
    );
    await tester.enterText(
      find.widgetWithText(TextFormField, 'Confirmar contraseña *'),
      '123456',
    );

    await tester.ensureVisible(find.text('Crear usuario'));
    await tester.tap(find.text('Crear usuario'));
    await tester.pumpAndSettle();
  }

  testWidgets(
    'abrir "Nuevo usuario" NO muestra "Usuario creado correctamente" y no '
    'navega (regresión del falso éxito)',
    (tester) async {
      await pumpScreen(tester);

      // Con la causa raíz sin corregir, este test fallaba: aparecía el snackbar
      // de éxito y además se intentaba `context.go` (sin router, lanzaba).
      expect(find.byType(SnackBar), findsNothing);
      expect(find.text('Usuario creado correctamente'), findsNothing);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets('crear usuario con fallo muestra error y NUNCA "Usuario creado '
      'correctamente"', (tester) async {
    await pumpScreen(tester, repository: FakeUsersRepository(fail: true));
    await fillAndSubmit(tester);

    expect(find.text('Usuario creado correctamente'), findsNothing);
    expect(find.textContaining('Error inesperado'), findsOneWidget);
  });
}
