import 'package:flutter_test/flutter_test.dart';
import 'package:app_locustaf/core/models/company_model.dart';
import 'package:app_locustaf/core/models/user_model.dart';
import 'package:app_locustaf/features/authentication/application/auth_state_listenable.dart';

void main() {
  group('isCompanyInactiveFor (TASK-016)', () {
    test('superadmin nunca se bloquea, aunque tenga companyId y empresa inactiva',
        () {
      expect(
        isCompanyInactiveFor(
          UserRole.superadmin,
          'empresaX',
          CompanyEstado.inactiva,
        ),
        isFalse,
      );
      expect(
        isCompanyInactiveFor(
          UserRole.superadmin,
          null,
          CompanyEstado.inactiva,
        ),
        isFalse,
      );
    });

    test('admin con empresa inactiva queda bloqueado', () {
      expect(
        isCompanyInactiveFor(
          UserRole.admin,
          'empresaX',
          CompanyEstado.inactiva,
        ),
        isTrue,
      );
    });

    test('supervisor y employee con empresa inactiva quedan bloqueados', () {
      expect(
        isCompanyInactiveFor(
          UserRole.supervisor,
          'empresaX',
          CompanyEstado.inactiva,
        ),
        isTrue,
      );
      expect(
        isCompanyInactiveFor(
          UserRole.employee,
          'empresaX',
          CompanyEstado.inactiva,
        ),
        isTrue,
      );
    });

    test('empresa activa nunca bloquea (cualquier rol con empresa)', () {
      expect(
        isCompanyInactiveFor(UserRole.admin, 'empresaX', CompanyEstado.activa),
        isFalse,
      );
      expect(
        isCompanyInactiveFor(
          UserRole.employee,
          'empresaX',
          CompanyEstado.activa,
        ),
        isFalse,
      );
    });

    test('sin empresa (companyId null) nunca bloquea', () {
      expect(
        isCompanyInactiveFor(UserRole.admin, null, CompanyEstado.inactiva),
        isFalse,
      );
      expect(
        isCompanyInactiveFor(
          UserRole.employee,
          null,
          CompanyEstado.inactiva,
        ),
        isFalse,
      );
    });

    test('sin rol definido (doc pendiente) no bloquea solo por estado', () {
      expect(
        isCompanyInactiveFor(null, 'empresaX', CompanyEstado.inactiva),
        isTrue,
      );
      expect(
        isCompanyInactiveFor(null, null, CompanyEstado.inactiva),
        isFalse,
      );
    });
  });
}