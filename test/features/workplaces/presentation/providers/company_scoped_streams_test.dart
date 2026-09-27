import 'package:app_locustaf/core/models/user_model.dart';
import 'package:app_locustaf/core/providers/data_providers.dart';
import 'package:app_locustaf/core/providers/firebase_providers.dart';
import 'package:app_locustaf/core/services/firestore_service.dart';
import 'package:app_locustaf/features/authentication/presentation/providers/auth_provider.dart';
import 'package:app_locustaf/features/employees/presentation/providers/users_provider.dart';
import 'package:app_locustaf/features/incidences/presentation/providers/incidences_provider.dart';
import 'package:app_locustaf/features/medical_documents/presentation/providers/medical_documents_provider.dart';
import 'package:app_locustaf/features/workplaces/presentation/providers/workplace_notifier.dart';
import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

/// Regresión del bug "Lugar no disponible" en Android.
///
/// Los streams scopeados a empresa se construían con `ref.read(repo)`. Como la
/// empresa del usuario se conoce recién cuando llega su documento (después del
/// primer frame en un arranque en frío), el repositorio se construía con
/// `companyId == null` → stream vacío, y el provider NUNCA se re-suscribía al
/// resolverse la empresa. El empleado veía "Lugar no disponible" para siempre
/// aunque su lugar existiera y estuviera activo.
class _CompanyHolder extends Notifier<String?> {
  @override
  String? build() => null;

  void set(String? value) => state = value;
}

final _holderProvider = NotifierProvider<_CompanyHolder, String?>(_CompanyHolder.new);

/// Espera a que el provider cumpla la condición (los streams de Firestore
/// resuelven de forma asíncrona y `.future` no es fiable al re-suscribirse).
Future<void> waitUntil(bool Function() condition, {String? reason}) async {
  for (var i = 0; i < 100; i++) {
    if (condition()) return;
    await Future<void>.delayed(const Duration(milliseconds: 10));
  }
  fail('Timeout esperando: ${reason ?? 'condición'}');
}

void main() {
  late FakeFirebaseFirestore fake;

  setUp(() {
    fake = FakeFirebaseFirestore();
  });

  ProviderContainer makeContainer() {
    final container = ProviderContainer(
      overrides: [
        firestoreServiceProvider.overrideWithValue(FirestoreService(fake)),
        currentCompanyIdProvider.overrideWith((ref) => ref.watch(_holderProvider)),
        // Los repos de incidencias/documentos leen rol y uid: sin override
        // tocarían FirebaseAuth, que no existe en un test unitario.
        userRoleProvider.overrideWithValue(UserRole.admin),
        currentUserIdProvider.overrideWithValue('u-1'),
      ],
    );
    // Un StreamProvider solo se suscribe si alguien lo escucha: sin estos
    // listeners el stream nunca se ejecuta y el provider queda en loading.
    container.listen(workplacesStreamProvider, (_, _) {});
    container.listen(usersStreamProvider, (_, _) {});
    container.listen(incidencesStreamProvider, (_, _) {});
    container.listen(medicalDocumentsStreamProvider, (_, _) {});
    return container;
  }

  group('Los streams scopeados a empresa se re-suscriben cuando llega la empresa', () {
    test('workplacesStreamProvider: null -> companyId trae el lugar del empleado',
        () async {
      await fake.collection('workplaces').doc('wp-1').set({
        'id': 'wp-1',
        'nombre': 'pizzeria',
        'companyId': 'company-1',
        'isActive': true,
        'createdAt': DateTime.utc(2026, 9, 13).toIso8601String(),
      });

      final container = makeContainer();

      // Primer frame: la empresa todavía no está resuelta -> lista vacía.
      expect(container.read(workplacesStreamProvider).value, anyOf(isNull, isEmpty));
      await waitUntil(
        () => container.read(workplacesStreamProvider).hasValue,
        reason: 'primer stream (companyId == null)',
      );
      expect(container.read(workplacesStreamProvider).value, isEmpty);

      // Llega el documento del usuario -> la empresa pasa a 'company-1'.
      container.read(_holderProvider.notifier).set('company-1');
      await waitUntil(
        () => (container.read(workplacesStreamProvider).value ?? []).any((w) => w.id == 'wp-1'),
        reason: 're-suscripción con la empresa resuelta',
      );

      final lista = container.read(workplacesStreamProvider).value!;
      expect(lista.single.nombre, 'pizzeria');
    });

    test('usersStreamProvider: idem con empleados de la empresa', () async {
      await fake.collection('users').doc('u-1').set({
        'id': 'u-1',
        'nombre': 'Empleado',
        'apellido': 'Uno',
        'email': 'e1@test.com',
        'dni': '37632535',
        'rol': 'employee',
        'companyId': 'company-1',
        'isActive': true,
        'isDeleted': false,
        'createdAt': DateTime.utc(2026, 9, 13).toIso8601String(),
      });

      final container = makeContainer();
      container.read(_holderProvider.notifier).set('company-1');

      await waitUntil(
        () => (container.read(usersStreamProvider).value ?? []).any((u) => u.id == 'u-1'),
        reason: 'empleados de company-1 -> estado: ${container.read(usersStreamProvider)}',
      );
    });

    test('incidencesStreamProvider: idem con incidencias de la empresa', () async {
      await fake.collection('incidences').doc('i-1').set({
        'id': 'i-1',
        'userId': 'u-1',
        'type': 'ausenciaJustificada',
        'estado': 'pendiente',
        'companyId': 'company-1',
        'fechaInicio': DateTime.utc(2026, 9, 13).toIso8601String(),
        'fechaFin': DateTime.utc(2026, 9, 13).toIso8601String(),
        'createdAt': DateTime.utc(2026, 9, 13).toIso8601String(),
      });

      final container = makeContainer();
      container.read(_holderProvider.notifier).set('company-1');

      await waitUntil(
        () => (container.read(incidencesStreamProvider).value ?? []).any((i) => i.id == 'i-1'),
        reason: 'incidencias de company-1',
      );
    });

    test('medicalDocumentsStreamProvider: idem con documentos de la empresa',
        () async {
      await fake.collection('medical_documents').doc('md-1').set({
        'id': 'md-1',
        'userId': 'u-1',
        'tipo': 'enfermedad',
        'motivo': 'Presentacion anual',
        'estado': 'pendiente',
        'companyId': 'company-1',
        'fechaInicio': DateTime.utc(2026, 9, 13).toIso8601String(),
        'fechaFin': DateTime.utc(2027, 9, 13).toIso8601String(),
        'createdAt': DateTime.utc(2026, 9, 13).toIso8601String(),
      });

      final container = makeContainer();
      container.read(_holderProvider.notifier).set('company-1');

      await waitUntil(
        () => (container.read(medicalDocumentsStreamProvider).value ?? [])
            .any((d) => d.id == 'md-1'),
        reason: 'documentos de company-1',
      );
    });
  });

  group('Aislamiento multiempresa se mantiene', () {
    test('workplacesStreamProvider: no trae lugares de otra empresa', () async {
      await fake.collection('workplaces').doc('wp-otro').set({
        'id': 'wp-otro',
        'nombre': 'otra empresa',
        'companyId': 'company-2',
        'isActive': true,
        'createdAt': DateTime.utc(2026, 9, 13).toIso8601String(),
      });
      await fake.collection('workplaces').doc('wp-mio').set({
        'id': 'wp-mio',
        'nombre': 'pizzeria',
        'companyId': 'company-1',
        'isActive': true,
        'createdAt': DateTime.utc(2026, 9, 13).toIso8601String(),
      });

      final container = makeContainer();
      container.read(_holderProvider.notifier).set('company-1');

      await waitUntil(
        () => (container.read(workplacesStreamProvider).value ?? []).isNotEmpty,
        reason: 'lugares de company-1',
      );
      expect(
        container.read(workplacesStreamProvider).value!.map((w) => w.id),
        ['wp-mio'],
      );
    });

    test('activeWorkplacesProvider: sigue filtrando los inactivos', () async {
      await fake.collection('workplaces').doc('wp-off').set({
        'id': 'wp-off',
        'nombre': 'cerrado',
        'companyId': 'company-1',
        'isActive': false,
        'createdAt': DateTime.utc(2026, 9, 13).toIso8601String(),
      });

      final container = makeContainer();
      container.read(_holderProvider.notifier).set('company-1');

      await waitUntil(
        () => container.read(workplacesStreamProvider).hasValue,
        reason: 'stream de workplaces',
      );
      expect(container.read(activeWorkplacesProvider).value, isEmpty);
    });
  });
}
