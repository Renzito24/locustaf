import 'package:app_locustaf/core/providers/data_providers.dart';
import 'package:app_locustaf/core/providers/firebase_providers.dart';
import 'package:app_locustaf/core/services/firestore_service.dart';
import 'package:app_locustaf/features/authentication/presentation/providers/auth_provider.dart';
import 'package:app_locustaf/features/incidences/presentation/providers/incidences_provider.dart';
import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

/// E2E del flujo de revisión de incidencias (admin/supervisor): aprobación y
/// rechazo persisten estado + reviewer, usando apples providers reales sobre
/// Firestore fake. El `currentUserIdProvider` (seam de testeo) evita depender
/// de `firebase_auth`.
void main() {
  const companyId = 'company-1';
  const supervisorId = 'supervisor-1';
  const userId = 'user-1';
  late FakeFirebaseFirestore fake;
  late ProviderContainer container;

  Future<void> seedIncidence({required String id}) async {
    await fake.collection('incidences').doc(id).set({
      'id': id,
      'userId': userId,
      'type': 'ausenciaJustificada',
      'fechaInicio': DateTime.now().toIso8601String(),
      'fechaFin': DateTime.now().toIso8601String(),
      'observaciones': 'Fui al médico',
      'estado': 'pendiente',
      'companyId': companyId,
      'isActive': true,
      'createdAt': DateTime.now().toIso8601String(),
    });
  }

  setUp(() {
    fake = FakeFirebaseFirestore();
    container = ProviderContainer(
      overrides: [
        firestoreServiceProvider.overrideWithValue(FirestoreService(fake)),
        currentCompanyIdProvider.overrideWithValue(companyId),
        currentUserIdProvider.overrideWithValue(supervisorId),
        userRoleProvider.overrideWithValue(null),
      ],
    );
  });

  tearDown(() => container.dispose());

  group('Revisión de incidencias (supervisor)', () {
    test('aprobar: estado aprobado + reviewer registrado', () async {
      await seedIncidence(id: 'inc-1');

      final notifier = container.read(incidenceApprovalProvider.notifier);
      await notifier.approve('inc-1');
      expect(container.read(incidenceApprovalProvider).hasValue, isTrue);

      final doc = await fake.collection('incidences').doc('inc-1').get();
      expect(doc.get('estado'), 'aprobado');
      expect(doc.get('reviewedBy'), supervisorId);
    });

    test('rechazar: estado rechazado + observación + reviewer', () async {
      await seedIncidence(id: 'inc-2');

      final notifier = container.read(incidenceApprovalProvider.notifier);
      await notifier.reject('inc-2', observacion: 'Falta adjuntar el certificado');
      expect(container.read(incidenceApprovalProvider).hasValue, isTrue);

      final doc = await fake.collection('incidences').doc('inc-2').get();
      expect(doc.get('estado'), 'rechazado');
      expect(doc.get('observacionRechazo'), 'Falta adjuntar el certificado');
      expect(doc.get('reviewedBy'), supervisorId);
    });
  });
}