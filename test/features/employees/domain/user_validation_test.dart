import 'package:app_locustaf/core/models/user_model.dart';
import 'package:app_locustaf/features/employees/domain/user_validation.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  UserModel user({
    String id = 'u1',
    String dni = '40987654',
    bool isDeleted = false,
  }) {
    return UserModel(
      id: id,
      nombre: 'Juan',
      apellido: 'Pérez',
      email: '$id@test.com',
      dni: dni,
      rol: UserRole.employee,
      isDeleted: isDeleted,
      createdAt: DateTime(2026, 1, 1),
    );
  }

  group('findDuplicateDni (TASK-031)', () {
    test('detecta un DNI ya registrado en la empresa', () {
      final users = [user(id: 'u1', dni: '40987654')];
      expect(
        findDuplicateDni(users, dni: '40987654'),
        '40987654',
      );
    });

    test('normaliza espacios al comparar', () {
      final users = [user(id: 'u1', dni: ' 40987654 ')];
      expect(findDuplicateDni(users, dni: '40987654'), ' 40987654 ');
    });

    test('ignora usuarios eliminados (soft-delete): permite re-utilizar el DNI', () {
      final users = [user(id: 'u1', dni: '40987654', isDeleted: true)];
      expect(findDuplicateDni(users, dni: '40987654'), isNull);
    });

    test('excluye al propio usuario al editar (no se auto-bloquea)', () {
      final users = [user(id: 'u1', dni: '40987654')];
      expect(
        findDuplicateDni(users, dni: '40987654', excludeUserId: 'u1'),
        isNull,
      );
    });

    test('devuelve null cuando el DNI no coincide con ningún usuario', () {
      final users = [user(id: 'u1', dni: '40987654')];
      expect(findDuplicateDni(users, dni: '12345678'), isNull);
    });

    test('devuelve null con lista vacía', () {
      expect(findDuplicateDni(const [], dni: '40987654'), isNull);
    });

    test('devuelve null con DNI vacío', () {
      final users = [user(id: 'u1', dni: '40987654')];
      expect(findDuplicateDni(users, dni: '  '), isNull);
    });

    test('considera duplicado aunque el usuario existente tenga diferente rol', () {
      final users = [
        user(id: 'u1', dni: '40987654').copyWith(rol: UserRole.supervisor),
      ];
      expect(findDuplicateDni(users, dni: '40987654'), '40987654');
    });
  });
}