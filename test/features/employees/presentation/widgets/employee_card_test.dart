import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:app_locustaf/core/models/user_model.dart';
import 'package:app_locustaf/features/employees/presentation/widgets/employee_card.dart';

void main() {
  group('EmployeeCard Tests', () {
    final employee = UserModel(
      id: '123',
      companyId: 'company123',
      email: 'test@locustaf.com',
      nombre: 'John',
      apellido: 'Doe',
      rol: UserRole.employee,
      lugarDeTrabajoId: 'workplace123',
      dni: '12345678',
      telefono: '1122334455',
      isActive: true,
      createdAt: DateTime.now(),
    );

    testWidgets('renders employee information correctly', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: EmployeeCard(
              employee: employee,
            ),
          ),
        ),
      );

      expect(find.text('John Doe'), findsOneWidget);
      expect(find.text('test@locustaf.com'), findsOneWidget);
      expect(find.text('DNI: 12345678'), findsOneWidget);
      expect(find.text('1122334455'), findsOneWidget);
      expect(find.text('Activo'), findsOneWidget);
      expect(find.text('JD'), findsOneWidget); // Initials
    });

    testWidgets('shows popup menu items if callbacks are provided', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: EmployeeCard(
              employee: employee,
              onEdit: () {},
              onToggleActive: () {},
              onHistory: () {},
              onDelete: () {},
              onPasswordReset: () {},
            ),
          ),
        ),
      );

      await tester.tap(find.byIcon(Icons.more_vert));
      await tester.pumpAndSettle();

      expect(find.text('Editar'), findsOneWidget);
      expect(find.text('Historial'), findsOneWidget);
      expect(find.text('Desactivar'), findsOneWidget);
      expect(find.text('Restablecer contraseña'), findsOneWidget);
      expect(find.text('Eliminar'), findsOneWidget);
    });
  });
}
