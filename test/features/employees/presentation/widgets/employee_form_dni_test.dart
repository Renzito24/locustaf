import 'package:app_locustaf/core/models/user_model.dart';
import 'package:app_locustaf/core/providers/data_providers.dart';
import 'package:app_locustaf/core/providers/firebase_providers.dart';
import 'package:app_locustaf/core/services/firestore_service.dart';
import 'package:app_locustaf/features/authentication/presentation/providers/auth_provider.dart';
import 'package:app_locustaf/features/employees/presentation/providers/users_provider.dart';
import 'package:app_locustaf/features/employees/presentation/widgets/employee_form.dart';
import 'package:app_locustaf/features/workplaces/data/models/workplace_model.dart';
import 'package:app_locustaf/features/workplaces/presentation/providers/workplace_notifier.dart';
import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

/// TASK-031 — El formulario de empleados debe impedir dar de alta un DNI que ya
/// exista en la empresa y no bloquear al editar al propio usuario.
void main() {
  const companyId = 'company-1';

  UserModel user({
    String id = 'u1',
    String dni = '40987654',
  }) {
    return UserModel(
      id: id,
      nombre: 'Ana',
      apellido: 'López',
      email: '$id@test.com',
      dni: dni,
      rol: UserRole.employee,
      lugarDeTrabajoId: null,
      companyId: companyId,
      createdAt: DateTime(2026, 1, 1),
    );
  }

  Widget buildApp({
    required List<UserModel> existingUsers,
    required bool isEditing,
    UserModel? initialData,
  }) {
    return ProviderScope(
      overrides: [
        usersStreamProvider
            .overrideWith((ref) => Stream.value(existingUsers)),
        activeWorkplacesProvider.overrideWith(
          (ref) => const AsyncValue.data(<WorkplaceModel>[]),
        ),
        userRoleProvider.overrideWithValue(UserRole.admin),
        currentCompanyIdProvider.overrideWithValue(companyId),
        firestoreServiceProvider
            .overrideWithValue(FirestoreService(FakeFirebaseFirestore())),
      ],
      child: MaterialApp(
        home: Scaffold(
          body: SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: EmployeeForm(
              isEditing: isEditing,
              initialData: initialData,
            ),
          ),
        ),
      ),
    );
  }

  Future<void> pumpForm(
    WidgetTester tester, {
    required List<UserModel> existingUsers,
    required bool isEditing,
    UserModel? initialData,
  }) async {
    tester.view.physicalSize = const Size(900, 2200);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(buildApp(
      existingUsers: existingUsers,
      isEditing: isEditing,
      initialData: initialData,
    ));
    await tester.pumpAndSettle();
  }

  testWidgets(
      'crear: un DNI ya existente en la empresa bloquea el alta y muestra error',
      (tester) async {
    await pumpForm(tester, existingUsers: [user()], isEditing: false);

    await tester.enterText(
        find.widgetWithText(TextFormField, 'Nombre *'), 'Carlos');
    await tester.enterText(
        find.widgetWithText(TextFormField, 'Apellido *'), 'Gómez');
    await tester.enterText(
        find.widgetWithText(TextFormField, 'Correo electrónico *'),
        'carlos@test.com');
    await tester.enterText(
        find.widgetWithText(TextFormField, 'DNI *'), '40987654');
    await tester.enterText(
        find.widgetWithText(TextFormField, 'Contraseña *'), '123456');
    await tester.enterText(
        find.widgetWithText(TextFormField, 'Confirmar contraseña *'),
        '123456');

    await tester.ensureVisible(find.text('Crear usuario'));
    await tester.tap(find.text('Crear usuario'));
    await tester.pumpAndSettle();

    expect(find.text('40987654'), findsWidgets);
    expect(find.textContaining('ya está registrado'), findsOneWidget);
  });

  testWidgets('crear: un DNI distinto a los existentes no marca duplicado',
      (tester) async {
    await pumpForm(tester, existingUsers: [user()], isEditing: false);

    await tester.enterText(
        find.widgetWithText(TextFormField, 'Nombre *'), 'Carlos');
    await tester.enterText(
        find.widgetWithText(TextFormField, 'Apellido *'), 'Gómez');
    await tester.enterText(
        find.widgetWithText(TextFormField, 'Correo electrónico *'),
        'carlos@test.com');
    await tester.enterText(
        find.widgetWithText(TextFormField, 'DNI *'), '11222333');
    await tester.enterText(
        find.widgetWithText(TextFormField, 'Contraseña *'), '123456');
    await tester.enterText(
        find.widgetWithText(TextFormField, 'Confirmar contraseña *'),
        '123456');

    await tester.ensureVisible(find.text('Crear usuario'));
    await tester.tap(find.text('Crear usuario'));
    await tester.pumpAndSettle();

    expect(find.textContaining('ya está registrado'), findsNothing);
  });

  testWidgets('editar: conservar el propio DNI no genera falso duplicado',
      (tester) async {
    final own = user(id: 'u1', dni: '40987654');
    await pumpForm(
      tester,
      existingUsers: [own],
      isEditing: true,
      initialData: own,
    );

    await tester.ensureVisible(find.text('Guardar cambios'));
    await tester.tap(find.text('Guardar cambios'));
    await tester.pumpAndSettle();

    expect(find.textContaining('ya está registrado'), findsNothing);
  });
}