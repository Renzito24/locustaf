import 'package:app_locustaf/core/models/user_model.dart';
import 'package:app_locustaf/core/providers/data_providers.dart';
import 'package:app_locustaf/core/providers/firebase_providers.dart';
import 'package:app_locustaf/core/services/firestore_service.dart';
import 'package:app_locustaf/features/attendance/presentation/providers/attendance_notifier.dart';
import 'package:app_locustaf/features/authentication/presentation/providers/auth_provider.dart';
import 'package:app_locustaf/features/employees/presentation/providers/users_provider.dart';
import 'package:app_locustaf/features/incidences/presentation/providers/incidences_provider.dart';
import 'package:app_locustaf/features/medical_documents/presentation/providers/medical_documents_provider.dart';
import 'package:app_locustaf/features/workplaces/presentation/providers/workplace_notifier.dart';
import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('Usuarios sin companyId (superadmin o cuentas viejas) no lanzan StateError',
      () async {
    final fakeFirestore = FakeFirebaseFirestore();
    final firestoreService = FirestoreService(fakeFirestore);

    final superadmin = UserModel(
      id: 'superadmin-1',
      email: 'admin@locustaf.com',
      nombre: 'Super',
      apellido: 'Admin',
      dni: '00000000',
      rol: UserRole.superadmin,
      companyId: null, // Sin empresa asignada
      isActive: true,
      isDeleted: false,
      createdAt: DateTime(2026, 1, 1),
    );

    final container = ProviderContainer(
      overrides: [
        firestoreServiceProvider.overrideWithValue(firestoreService),
        sessionProvider.overrideWith(
          () => _FakeSessionNotifier(
            SessionState(
              isLoading: false,
              user: superadmin,
              companyId: null,
              role: UserRole.superadmin,
              userId: superadmin.id,
            ),
          ),
        ),
      ],
    );
    addTearDown(container.dispose);

    // 1. currentCompanyIdProvider debe ser null
    expect(container.read(currentCompanyIdProvider), isNull);

    // 2. Repositorios no deben arrojar StateError
    final wpRepo = container.read(workplaceRepositoryProvider);
    final attRepo = container.read(attendanceRepositoryProvider);
    final usersRepo = container.read(usersRepositoryProvider);
    final incRepo = container.read(incidenceRepositoryProvider);
    final medRepo = container.read(medicalDocumentRepositoryProvider);

    // 3. Streams deben emitir listas vacías de forma segura
    final workplaces = await wpRepo.getWorkplaces().first;
    expect(workplaces, isEmpty);

    final attendances = await attRepo.getAllAttendances().first;
    expect(attendances, isEmpty);

    final activeAttendances = await attRepo.getAllActiveAttendances().first;
    expect(activeAttendances, isEmpty);

    final page = await attRepo.getAttendancePage(limit: 10);
    expect(page.items, isEmpty);
    expect(page.hasMore, isFalse);

    final users = await usersRepo.getUsers().first;
    expect(users, isEmpty);

    final incidences = await incRepo.getIncidences().first;
    expect(incidences, isEmpty);

    final medDocs = await medRepo.getDocuments().first;
    expect(medDocs, isEmpty);
  });
}

class _FakeSessionNotifier extends SessionNotifier {
  final SessionState _initial;
  _FakeSessionNotifier(this._initial);

  @override
  SessionState build() => _initial;
}
