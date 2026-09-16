import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:app_locustaf/core/models/user_model.dart';
import 'package:app_locustaf/core/providers/data_providers.dart';
import 'package:app_locustaf/features/employees/domain/repositories/users_repository.dart';
import 'package:app_locustaf/features/employees/presentation/providers/users_provider.dart';

/// Fase B — Corrección: al abrir "Nuevo usuario" NO debe aparecer el mensaje
/// "Usuario creado correctamente" antes de crear nada. La causa era que el
/// estado inicial del notifier era éxito (`AsyncData(null)`) y `ref.listen`
/// dispara con el valor actual al montar la pantalla. El estado inicial ahora
/// es `idle`, que no es sinónimo de éxito, y el éxito solo existe después de
/// que `createUser` retorna.
class FakeUsersRepository implements UsersRepository {
  FakeUsersRepository({this.fail = false});

  final bool fail;
  int createCalls = 0;

  @override
  Stream<List<UserModel>> getUsers() => const Stream.empty();

  @override
  Future<void> createUser(UserModel user, String password) async {
    createCalls++;
    if (fail) throw Exception('fallo simulado');
  }

  @override
  Future<void> updateUser(UserModel user) async {}

  @override
  Future<void> deleteUser(String uid) async {}
}

void main() {
  const companyId = 'company-1';

  EmployeeFormData formData() => const EmployeeFormData(
    nombre: 'Carlos',
    apellido: 'Gómez',
    email: 'carlos@test.com',
    dni: '11222333',
    password: '123456',
    rol: UserRole.employee,
  );

  ProviderContainer makeContainer(FakeUsersRepository repository) {
    return ProviderContainer(
      overrides: [
        usersRepositoryProvider.overrideWithValue(repository),
        currentCompanyIdProvider.overrideWithValue(companyId),
      ],
    );
  }

  test(
    'estado inicial es idle, no éxito: abrir la pantalla no muestra éxito',
    () {
      final repository = FakeUsersRepository();
      final container = makeContainer(repository);
      addTearDown(container.dispose);

      final state = container.read(createEmployeeProvider);

      expect(state.status, CreateEmployeeStatus.idle);
      expect(state.isLoading, isFalse);
      expect(state.error, isNull);
      // El estado inicial nunca debe presentarse como éxito.
      expect(state.status, isNot(CreateEmployeeStatus.success));
    },
  );

  test('éxito solo ocurre DESPUÉS de que createUser terminó (y reset vuelve '
      'a idle)', () async {
    final repository = FakeUsersRepository();
    final container = makeContainer(repository);
    addTearDown(container.dispose);

    await container
        .read(createEmployeeProvider.notifier)
        .createEmployee(formData());

    expect(repository.createCalls, 1);
    expect(
      container.read(createEmployeeProvider).status,
      CreateEmployeeStatus.success,
    );

    // Al volver a abrir el formulario (reset) nunca debe quedar en éxito.
    container.read(createEmployeeProvider.notifier).reset();
    expect(
      container.read(createEmployeeProvider).status,
      CreateEmployeeStatus.idle,
    );
  });

  test('fallo de createUser → failure con el error, nunca success', () async {
    final repository = FakeUsersRepository(fail: true);
    final container = makeContainer(repository);
    addTearDown(container.dispose);

    await container
        .read(createEmployeeProvider.notifier)
        .createEmployee(formData());

    final state = container.read(createEmployeeProvider);
    expect(state.status, CreateEmployeeStatus.failure);
    expect(state.error, isA<Exception>());
    expect(state.status, isNot(CreateEmployeeStatus.success));
  });
}
