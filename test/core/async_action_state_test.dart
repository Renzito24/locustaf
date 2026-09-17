import 'package:app_locustaf/core/providers/async_action_state.dart';
import 'package:app_locustaf/core/providers/firebase_providers.dart';
import 'package:app_locustaf/core/services/firestore_service.dart';
import 'package:app_locustaf/features/companies/presentation/providers/company_action_provider.dart';
import 'package:app_locustaf/features/employees/presentation/providers/delete_employee_notifier.dart';
import 'package:app_locustaf/features/employees/presentation/providers/reset_password_notifier.dart';
import 'package:app_locustaf/features/employees/presentation/providers/update_employee_notifier.dart';
import 'package:app_locustaf/features/incidences/presentation/providers/incidences_provider.dart';
import 'package:app_locustaf/features/medical_documents/presentation/providers/medical_documents_provider.dart';
import 'package:app_locustaf/features/workplaces/presentation/providers/workplace_notifier.dart';
import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

/// Auditoría transversal de mensajes fantasma.
///
/// Causa raíz corregida: los providers de acción eran `AsyncNotifier<void>`
/// cuyo valor inicial era `AsyncData(null)` (éxito). Como `ref.listen` emite el
/// estado actual al montar una pantalla, cualquier listener de snackbar
/// mostraba éxito sin haber ejecutado nada. Ahora todos arrancan en
/// `AsyncActionStatus.idle` y el éxito solo existe tras una operación real
/// (secuencia idle → loading → success).
void main() {
  group('Los 16 providers de acción arrancan en idle (nunca en éxito)', () {
    late ProviderContainer container;

    setUp(() {
      container = ProviderContainer();
    });

    tearDown(() => container.dispose());

    test('companies', () {
      expect(
        container.read(createCompanyProvider).status,
        AsyncActionStatus.idle,
      );
      expect(
        container.read(updateCompanyProvider).status,
        AsyncActionStatus.idle,
      );
      expect(
        container.read(toggleCompanyStateProvider).status,
        AsyncActionStatus.idle,
      );
      expect(
        container.read(registerPaymentProvider).status,
        AsyncActionStatus.idle,
      );
    });

    test('employees', () {
      expect(
        container.read(deleteEmployeeProvider).status,
        AsyncActionStatus.idle,
      );
      expect(
        container.read(updateEmployeeProvider).status,
        AsyncActionStatus.idle,
      );
      expect(
        container.read(resetPasswordProvider).status,
        AsyncActionStatus.idle,
      );
    });

    test('workplaces', () {
      expect(
        container.read(workplaceCreateProvider).status,
        AsyncActionStatus.idle,
      );
      expect(
        container.read(workplaceUpdateProvider).status,
        AsyncActionStatus.idle,
      );
      expect(
        container.read(workplaceDeleteProvider).status,
        AsyncActionStatus.idle,
      );
    });

    test('medical_documents', () {
      expect(
        container.read(medicalDocumentDeleteProvider).status,
        AsyncActionStatus.idle,
      );
      expect(
        container.read(medicalDocumentApprovalProvider).status,
        AsyncActionStatus.idle,
      );
    });

    test('incidences', () {
      expect(
        container.read(incidenceCreateProvider).status,
        AsyncActionStatus.idle,
      );
      expect(
        container.read(incidenceUpdateProvider).status,
        AsyncActionStatus.idle,
      );
      expect(
        container.read(incidenceDeleteProvider).status,
        AsyncActionStatus.idle,
      );
      expect(
        container.read(incidenceApprovalProvider).status,
        AsyncActionStatus.idle,
      );
    });
  });

  group('Creación de empresa: éxito solo después de una operación real', () {
    late FakeFirebaseFirestore fake;
    late ProviderContainer container;

    setUp(() {
      fake = FakeFirebaseFirestore();
      container = ProviderContainer(
        overrides: [
          firestoreServiceProvider.overrideWithValue(FirestoreService(fake)),
        ],
      );
    });

    tearDown(() => container.dispose());

    test(
      'secuencia idle → loading → success (un ref.listen al montar nunca ve éxito)',
      () async {
        final recorded = <AsyncActionStatus>[];
        // fireImmediately: true replica el disparo que hace ref.listen al
        // montar una pantalla (prev == null).
        container.listen(
          createCompanyProvider,
          (prev, next) => recorded.add(next.status),
          fireImmediately: true,
        );

        await container
            .read(createCompanyProvider.notifier)
            .createCompany(const CompanyFormData(
              nombreComercial: 'ACME SA',
              razonSocial: 'ACME SA',
              cuit: '30-12345678-9',
            ));

        expect(
          recorded,
          [
            AsyncActionStatus.idle,
            AsyncActionStatus.loading,
            AsyncActionStatus.success,
          ],
        );

        container.read(createCompanyProvider.notifier).reset();
        expect(
          container.read(createCompanyProvider).status,
          AsyncActionStatus.idle,
        );
      },
    );
  });
}