import 'package:app_locustaf/core/models/company_model.dart';
import 'package:app_locustaf/core/models/user_model.dart';
import 'package:app_locustaf/core/providers/data_providers.dart';
import 'package:app_locustaf/core/providers/firebase_providers.dart';
import 'package:app_locustaf/core/services/firestore_service.dart';
import 'package:app_locustaf/features/attendance/presentation/screens/attendance_screen.dart';
import 'package:app_locustaf/features/authentication/presentation/providers/auth_provider.dart';
import 'package:app_locustaf/features/dashboard/presentation/screens/employee_home_screen.dart';
import 'package:app_locustaf/features/dashboard/presentation/screens/home_screen.dart';
import 'package:app_locustaf/features/history/presentation/screens/history_screen.dart';
import 'package:app_locustaf/features/incidences/presentation/screens/incidences_screen.dart';
import 'package:app_locustaf/features/medical_documents/presentation/screens/medical_documents_screen.dart';
import 'package:app_locustaf/features/profile/presentation/screens/profile_screen.dart';
import 'package:app_locustaf/features/reports/presentation/screens/employee_reports_screen.dart';
import 'package:app_locustaf/features/workplaces/data/models/workplace_model.dart';
import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late FakeFirebaseFirestore fakeFirestore;
  late FirestoreService firestoreService;

  const cecibauCompanyId = 'tXAofBiCA0n2MbAs9oOX';
  const cecibauWorkplaceId = 'z4kUjQ1E9o62QjT7gqXF';

  const controlCompanyId = 'comp-control';
  const controlWorkplaceId = 'wp-control';

  final juan = UserModel(
    id: 'uid-juan',
    email: 'juan@gmail.com',
    nombre: 'Juan',
    apellido: 'Perez',
    dni: '30111222',
    rol: UserRole.employee,
    companyId: cecibauCompanyId,
    lugarDeTrabajoId: cecibauWorkplaceId,
    isActive: true,
    isDeleted: false,
    createdAt: DateTime(2026, 1, 1),
  );

  final mamani = UserModel(
    id: 'uid-mamani',
    email: 'mamani@gmail.com',
    nombre: 'Mamani',
    apellido: 'Test',
    dni: '30222333',
    rol: UserRole.employee,
    companyId: cecibauCompanyId,
    lugarDeTrabajoId: cecibauWorkplaceId,
    isActive: true,
    isDeleted: false,
    createdAt: DateTime(2026, 2, 1),
  );

  final enzo = UserModel(
    id: 'uid-enzo',
    email: 'enzo@gmail.com',
    nombre: 'Enzo',
    apellido: 'Test',
    dni: '30333444',
    rol: UserRole.employee,
    companyId: cecibauCompanyId,
    lugarDeTrabajoId: cecibauWorkplaceId,
    isActive: true,
    isDeleted: false,
    createdAt: DateTime(2026, 3, 1),
  );

  final controlEmployee = UserModel(
    id: 'uid-control',
    email: 'empleado@locustaf.com',
    nombre: 'Empleado',
    apellido: 'Control',
    dni: '30444555',
    rol: UserRole.employee,
    companyId: controlCompanyId,
    lugarDeTrabajoId: controlWorkplaceId,
    isActive: true,
    isDeleted: false,
    createdAt: DateTime(2026, 1, 1),
  );

  final adminUser = UserModel(
    id: 'uid-admin',
    email: 'admin@locustaf.com',
    nombre: 'Admin',
    apellido: 'Locustaf',
    dni: '30555666',
    rol: UserRole.admin,
    companyId: controlCompanyId,
    isActive: true,
    isDeleted: false,
    createdAt: DateTime(2026, 1, 1),
  );

  final supervisorUser = UserModel(
    id: 'uid-supervisor',
    email: 'supervisor@locustaf.com',
    nombre: 'Supervisor',
    apellido: 'Locustaf',
    dni: '30666777',
    rol: UserRole.supervisor,
    companyId: controlCompanyId,
    isActive: true,
    isDeleted: false,
    createdAt: DateTime(2026, 1, 1),
  );

  final cecibauCompany = CompanyModel(
    id: cecibauCompanyId,
    nombreComercial: 'CECIBAU',
    razonSocial: 'CECIBAU S.R.L.',
    cuit: '30-71112222-3',
    diasLaborables: const [1, 2, 3, 4, 5],
    toleranciaCheckIn: 15,
    createdAt: DateTime(2026, 1, 1),
  );

  final cecibauWorkplace = WorkplaceModel(
    id: cecibauWorkplaceId,
    nombre: 'Sede Central CECIBAU',
    companyId: cecibauCompanyId,
    isActive: true,
    toleranciaMinutos: 15,
    createdAt: DateTime(2026, 1, 1),
  );

  final controlCompany = CompanyModel(
    id: controlCompanyId,
    nombreComercial: 'Locustaf Empresa',
    razonSocial: 'Locustaf S.A.',
    cuit: '30-72223333-4',
    diasLaborables: const [1, 2, 3, 4, 5],
    toleranciaCheckIn: 15,
    createdAt: DateTime(2026, 1, 1),
  );

  final controlWorkplace = WorkplaceModel(
    id: controlWorkplaceId,
    nombre: 'Sede Central Control',
    companyId: controlCompanyId,
    isActive: true,
    toleranciaMinutos: 15,
    createdAt: DateTime(2026, 1, 1),
  );

  setUp(() async {
    fakeFirestore = FakeFirebaseFirestore();
    firestoreService = FirestoreService(fakeFirestore);

    // Seed companies
    await fakeFirestore.collection('companies').doc(cecibauCompanyId).set(cecibauCompany.toJson());
    await fakeFirestore.collection('companies').doc(controlCompanyId).set(controlCompany.toJson());

    // Seed workplaces
    await fakeFirestore.collection('workplaces').doc(cecibauWorkplaceId).set(cecibauWorkplace.toJson());
    await fakeFirestore.collection('workplaces').doc(controlWorkplaceId).set(controlWorkplace.toJson());

    // Seed users
    for (final u in [juan, mamani, enzo, controlEmployee, adminUser, supervisorUser]) {
      await fakeFirestore.collection('users').doc(u.id).set(u.toJson());
    }

    // Seed attendances for employees
    for (final u in [juan, mamani, enzo, controlEmployee]) {
      await fakeFirestore.collection('attendances').add({
        'id': 'att-${u.id}-1',
        'userId': u.id,
        'companyId': u.companyId,
        'workplaceId': u.lugarDeTrabajoId,
        'date': '2026-09-27',
        'checkInTime': DateTime(2026, 9, 27, 9, 0).toUtc().toIso8601String(),
        'checkOutTime': DateTime(2026, 9, 27, 17, 0).toUtc().toIso8601String(),
        'durationMinutes': 480,
        'status': 'completed',
        'isLate': false,
        'createdAt': DateTime(2026, 9, 27, 9, 0).toUtc().toIso8601String(),
      });
    }
  });

  Widget createWidgetForScreen(Widget screen, UserModel user) {
    final sessionState = SessionState(
      isLoading: false,
      user: user,
      companyId: user.companyId,
      role: user.rol,
      userId: user.id,
      isUserBlocked: false,
      isCompanyInactive: false,
      needsOnboarding: false,
    );

    return ProviderScope(
      overrides: [
        firestoreServiceProvider.overrideWithValue(firestoreService),
        sessionProvider.overrideWith(() => _StaticSessionNotifier(sessionState)),
        currentCompanyIdProvider.overrideWithValue(user.companyId),
        currentUserIdProvider.overrideWithValue(user.id),
        userRoleProvider.overrideWithValue(user.rol),
        currentUserModelProvider.overrideWithValue(user),
        currentAppUserProvider.overrideWith((ref) => Stream.value(user)),
      ],
      child: MaterialApp(
        home: Scaffold(body: screen),
      ),
    );
  }

  group('VERIFICACIÓN EMPLEADOS (Juan, Mamani, Enzo, Control)', () {
    final employees = [
      ('Juan (CECIBAU)', juan),
      ('Mamani (CECIBAU)', mamani),
      ('Enzo (CECIBAU)', enzo),
      ('Control (Locustaf)', controlEmployee),
    ];

    for (final (label, user) in employees) {
      testWidgets('$label: EmployeeHomeScreen carga sin errores ni markNeedsBuild', (tester) async {
        await tester.pumpWidget(createWidgetForScreen(const EmployeeHomeScreen(), user));
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 500));

        expect(find.text('Principal'), findsOneWidget);
        expect(tester.takeException(), isNull);
      });

      testWidgets('$label: AttendanceScreen carga sin errores (línea 58 activeAttendanceProvider)', (tester) async {
        await tester.pumpWidget(createWidgetForScreen(const AttendanceScreen(), user));
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 500));

        expect(find.text('Asistencia'), findsOneWidget);
        expect(tester.takeException(), isNull);
      });

      testWidgets('$label: HistoryScreen carga sin errores', (tester) async {
        tester.view.physicalSize = const Size(1280, 800);
        tester.view.devicePixelRatio = 1.0;
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);

        await tester.pumpWidget(createWidgetForScreen(const HistoryScreen(), user));
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 500));

        expect(find.text('Historial de Asistencias'), findsOneWidget);
        expect(tester.takeException(), isNull);
      });

      testWidgets('$label: EmployeeReportsScreen carga sin errores', (tester) async {
        await tester.pumpWidget(createWidgetForScreen(const EmployeeReportsScreen(), user));
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 500));

        expect(find.text('Reportes'), findsOneWidget);
        expect(tester.takeException(), isNull);
      });

      testWidgets('$label: IncidencesScreen carga sin permission-denied', (tester) async {
        await tester.pumpWidget(createWidgetForScreen(const IncidencesScreen(), user));
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 500));

        expect(find.text('Incidencias'), findsOneWidget);
        expect(tester.takeException(), isNull);
      });

      testWidgets('$label: MedicalDocumentsScreen carga sin permission-denied', (tester) async {
        await tester.pumpWidget(createWidgetForScreen(const MedicalDocumentsScreen(), user));
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 500));

        expect(find.text('Documentación Médica'), findsOneWidget);
        expect(tester.takeException(), isNull);
      });

      testWidgets('$label: ProfileScreen carga sin errores', (tester) async {
        await tester.pumpWidget(createWidgetForScreen(const ProfileScreen(), user));
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 500));

        expect(find.textContaining(user.nombre), findsWidgets);
        expect(tester.takeException(), isNull);
      });
    }
  });

  group('VERIFICACIÓN ADMIN Y SUPERVISOR', () {
    testWidgets('Admin: HomeScreen carga métricas administrativas sin error', (tester) async {
      await tester.pumpWidget(createWidgetForScreen(const HomeScreen(), adminUser));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 500));

      expect(tester.takeException(), isNull);
    });

    testWidgets('Supervisor: HomeScreen carga métricas supervisor sin error', (tester) async {
      await tester.pumpWidget(createWidgetForScreen(const HomeScreen(), supervisorUser));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 500));

      expect(tester.takeException(), isNull);
    });
  });

  group('VERIFICACIÓN DE SESIÓN RESTAURADA Y SPLASH', () {
    testWidgets('Splash retiene al usuario mientras isProfileLoading es true', (tester) async {
      final loadingSession = const SessionState(
        isLoading: true,
        user: null,
        companyId: null,
        role: null,
      );

      final container = ProviderContainer(
        overrides: [
          sessionProvider.overrideWith(() => _StaticSessionNotifier(loadingSession)),
          currentCompanyIdProvider.overrideWith((ref) => ref.watch(sessionProvider).companyId),
        ],
      );

      expect(container.read(sessionProvider).isLoading, isTrue);
      expect(container.read(currentCompanyIdProvider), isNull);
    });

    testWidgets('Al resolver la sesión, companyId y rol están disponibles inmediatamente', (tester) async {
      final sessionState = SessionState(
        isLoading: false,
        user: juan,
        companyId: juan.companyId,
        role: juan.rol,
        userId: juan.id,
      );

      final container = ProviderContainer(
        overrides: [
          sessionProvider.overrideWith(() => _StaticSessionNotifier(sessionState)),
          currentCompanyIdProvider.overrideWith((ref) => ref.watch(sessionProvider).companyId),
          userRoleProvider.overrideWith((ref) => ref.watch(sessionProvider).role),
        ],
      );

      expect(container.read(sessionProvider).isLoading, isFalse);
      expect(container.read(currentCompanyIdProvider), cecibauCompanyId);
      expect(container.read(userRoleProvider), UserRole.employee);
    });
  });
}

class _StaticSessionNotifier extends SessionNotifier {
  final SessionState _initialState;
  _StaticSessionNotifier(this._initialState);

  @override
  SessionState build() {
    ref.keepAlive();
    return _initialState;
  }
}
