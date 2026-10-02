import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:app_locustaf/features/profile/presentation/screens/profile_screen.dart';
import 'package:app_locustaf/features/profile/presentation/providers/profile_provider.dart';
import 'package:app_locustaf/features/authentication/presentation/providers/auth_provider.dart';
import 'package:app_locustaf/features/workplaces/presentation/providers/workplace_notifier.dart';
import 'package:app_locustaf/core/models/user_model.dart';
import 'package:app_locustaf/features/workplaces/data/models/workplace_model.dart';

class MockProfileUpdateNotifier extends Notifier<ProfileUpdateState> implements ProfileUpdateNotifier {
  @override
  ProfileUpdateState build() => const ProfileUpdateState.idle();

  @override
  Future<void> updateProfile({required String userId, required String nombre, required String apellido, String? telefono}) async {}

  @override
  void reset() {
    state = const ProfileUpdateState.idle();
  }
}

class MockPasswordChangeNotifier extends Notifier<PasswordChangeState> implements PasswordChangeNotifier {
  @override
  PasswordChangeState build() => const PasswordChangeState.idle();

  @override
  Future<void> changePassword({required String currentPassword, required String newPassword}) async {}

  @override
  void reset() {
    state = const PasswordChangeState.idle();
  }
}

void main() {
  final testUser = UserModel(
    id: 'user1',
    email: 'test@test.com',
    nombre: 'Juan',
    apellido: 'Perez',
    dni: '12345678',
    rol: UserRole.employee,
    createdAt: DateTime(2026, 1, 1),
    isActive: true,
    isDeleted: false,
    companyId: 'comp1',
    lugarDeTrabajoId: 'wp1',
  );

  final testWorkplace = WorkplaceModel(
    id: 'wp1',
    nombre: 'Sede Central',
    direccion: 'Calle Falsa 123',
    companyId: 'comp1',
    isActive: true,
    radio: 100.0,
    latitud: -34.0,
    longitud: -58.0,
    createdAt: DateTime(2026, 1, 1),
  );

  Widget createSubject({
    UserModel? user,
    List<WorkplaceModel>? workplaces,
  }) {
    return ProviderScope(
      overrides: [
        currentAppUserProvider.overrideWith((ref) => Stream.value(user ?? testUser)),
        activeWorkplacesProvider.overrideWith((ref) => AsyncValue.data(workplaces ?? [testWorkplace])),
        profileUpdateProvider.overrideWith(() => MockProfileUpdateNotifier()),
        passwordChangeProvider.overrideWith(() => MockPasswordChangeNotifier()),
      ],
      child: const MaterialApp(
        home: Scaffold(
          body: ProfileScreen(),
        ),
      ),
    );
  }

  group('ProfileScreen', () {
    testWidgets('renderiza correctamente el estado inicial de solo lectura', (tester) async {
      await tester.pumpWidget(createSubject());
      await tester.pumpAndSettle();

      // Debería mostrar la info personal
      expect(find.text('Juan Perez'), findsWidgets);
      expect(find.text('test@test.com'), findsWidgets);
      expect(find.text('12345678'), findsWidgets);

      // Debería mostrar el lugar de trabajo
      expect(find.text('Sede Central'), findsOneWidget);

      // Botón de editar
      expect(find.text('Editar perfil'), findsOneWidget);
    });

    testWidgets('cambia a modo edición y muestra el formulario', (tester) async {
      await tester.pumpWidget(createSubject());
      await tester.pumpAndSettle();

      await tester.tap(find.text('Editar perfil'));
      await tester.pumpAndSettle();

      // Debería mostrar los botones Cancelar y Guardar
      expect(find.text('Cancelar'), findsOneWidget);
      expect(find.text('Guardar'), findsOneWidget);
      expect(find.text('Editar información'), findsOneWidget);

      // Los TextField deberían estar con los valores actuales
      expect(find.text('Juan'), findsWidgets);
      expect(find.text('Perez'), findsWidgets);
    });

    testWidgets('muestra la sección de cambio de contraseña al expandir', (tester) async {
      await tester.pumpWidget(createSubject());
      await tester.pumpAndSettle();

      // Tocar en "Seguridad"
      await tester.ensureVisible(find.text('Seguridad'));
      await tester.tap(find.text('Seguridad'));
      await tester.pumpAndSettle();

      expect(find.text('Contraseña actual'), findsOneWidget);
      expect(find.text('Nueva contraseña'), findsOneWidget);
      expect(find.text('Confirmar contraseña'), findsOneWidget);
      expect(find.text('Cambiar contraseña'), findsOneWidget);
    });
  });
}
