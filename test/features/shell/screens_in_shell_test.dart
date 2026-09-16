import 'package:app_locustaf/core/models/user_model.dart';
import 'package:app_locustaf/core/router/app_routes.dart';
import 'package:app_locustaf/features/authentication/presentation/providers/auth_provider.dart';
import 'package:app_locustaf/features/dashboard/presentation/widgets/dashboard_layout.dart';
import 'package:app_locustaf/features/employees/presentation/providers/users_provider.dart';
import 'package:app_locustaf/features/incidences/data/models/incidence_model.dart';
import 'package:app_locustaf/features/incidences/presentation/providers/incidences_provider.dart';
import 'package:app_locustaf/features/incidences/presentation/screens/incidences_screen.dart';
import 'package:app_locustaf/features/incidences/presentation/widgets/incidence_card.dart';
import 'package:app_locustaf/features/medical_documents/data/models/medical_document_model.dart';
import 'package:app_locustaf/features/medical_documents/presentation/providers/medical_documents_provider.dart';
import 'package:app_locustaf/features/medical_documents/presentation/screens/medical_documents_screen.dart';
import 'package:app_locustaf/features/medical_documents/presentation/widgets/medical_document_card.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';

/// Regresión de layout "en el shell real" (Fase B — Corrección).
///
/// A diferencia de los tests de pantalla aislada, acá se monta la composición
/// REAL que corre en el dispositivo: GoRouter → ShellRoute →
/// [DashboardLayout] (AppBar móvil + drawer) → pantalla, sobre un MediaQuery
/// con métricas de teléfono, padding de barra de estado/navegación y escala de
/// texto (textScale 1.3, accesibilidad). El objetivo es acercarse lo máximo
/// posible al entorno físico de Android: si algo desborda en un teléfono real,
/// este test debe reproducirlo.
void main() {
  final user = UserModel(
    id: 'u1',
    nombre: 'Juan',
    apellido: 'Pérez',
    email: 'juan@test.com',
    dni: '33445566',
    rol: UserRole.employee,
    createdAt: DateTime(2026),
  );

  final incidence = IncidenceModel(
    id: 'i1',
    userId: 'u1',
    type: IncidenceType.vacaciones,
    fechaInicio: DateTime(2026, 1, 1),
    fechaFin: DateTime(2026, 1, 20),
    observaciones: 'Vacaciones de verano',
    createdAt: DateTime(2026),
  );

  final doc = MedicalDocumentModel(
    id: 'd1',
    userId: 'u1',
    tipo: MedicalDocumentTipo.enfermedad,
    fechaInicio: DateTime(2026, 1, 1),
    fechaFin: DateTime(2026, 12, 31),
    motivo: 'Certificado por reposo',
    createdAt: DateTime(2026),
  );

  Future<void> pumpInShell(
    WidgetTester tester, {
    required Size size,
    required ProviderScope scope,
  }) async {
    tester.view.physicalSize = size;
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(scope);
    await tester.pumpAndSettle();
  }

  // Composición real de la app: GoRouter → ShellRoute → DashboardLayout →
  // pantalla, con MediaQuery de teléfono (barra de estado arriba, navegación
  // abajo y escala de texto 1.3). Las listas de overrides se pasan inline a
  // ProviderScope en cada test (sin tipos nombrados, inferidos por Riverpod).
  Widget buildShellApp({required String path, required Widget screen}) {
    final router = GoRouter(
      initialLocation: path,
      routes: [
        ShellRoute(
          builder: (context, state, child) => DashboardLayout(child: child),
          routes: [GoRoute(path: path, builder: (_, _) => screen)],
        ),
      ],
    );

    return MaterialApp.router(
      routerConfig: router,
      builder: (context, child) {
        final mq = MediaQuery.of(context);
        return MediaQuery(
          data: mq.copyWith(
            padding: mq.padding.copyWith(top: 24, bottom: 24),
            viewPadding: mq.viewPadding.copyWith(top: 24, bottom: 24),
            textScaler: const TextScaler.linear(1.3),
          ),
          child: child!,
        );
      },
    );
  }

  group('Incidencias en el shell real (teléfono chico, textScale 1.3)', () {
    final overrides = [
      usersStreamProvider.overrideWith((ref) => Stream.value([user])),
      userRoleProvider.overrideWith((ref) => UserRole.admin),
    ];

    testWidgets('con datos no produce overflow y el listado scrollea', (
      tester,
    ) async {
      await pumpInShell(
        tester,
        size: const Size(360, 640),
        scope: ProviderScope(
          overrides: [
            ...overrides,
            filteredIncidencesProvider.overrideWith((ref) => [incidence]),
          ],
          child: buildShellApp(
            path: RoutePaths.incidences,
            screen: const IncidencesScreen(),
          ),
        ),
      );

      expect(tester.takeException(), isNull);

      await tester.scrollUntilVisible(
        find.byType(IncidenceCard),
        400,
        maxScrolls: 30,
        scrollable: find.byType(Scrollable).first,
      );
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
      expect(find.byType(IncidenceCard), findsWidgets);
    });

    testWidgets('con datos y pantalla muy baja (360x568) no produce overflow', (
      tester,
    ) async {
      await pumpInShell(
        tester,
        size: const Size(360, 568),
        scope: ProviderScope(
          overrides: [
            ...overrides,
            filteredIncidencesProvider.overrideWith((ref) => [incidence]),
          ],
          child: buildShellApp(
            path: RoutePaths.incidences,
            screen: const IncidencesScreen(),
          ),
        ),
      );

      expect(tester.takeException(), isNull);

      await tester.scrollUntilVisible(
        find.byType(IncidenceCard),
        400,
        maxScrolls: 30,
        scrollable: find.byType(Scrollable).first,
      );
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
    });

    testWidgets('sin datos el estado vacío es alcanzable scrolleando', (
      tester,
    ) async {
      await pumpInShell(
        tester,
        size: const Size(360, 640),
        scope: ProviderScope(
          overrides: overrides,
          child: buildShellApp(
            path: RoutePaths.incidences,
            screen: const IncidencesScreen(),
          ),
        ),
      );

      expect(tester.takeException(), isNull);

      await tester.scrollUntilVisible(
        find.text('Sin incidencias'),
        300,
        maxScrolls: 30,
        scrollable: find.byType(Scrollable).first,
      );
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
      expect(find.text('Sin incidencias'), findsOneWidget);
    });
  });

  group(
    'Documentación médica en el shell real (teléfono chico, textScale 1.3)',
    () {
      final overrides = [
        usersStreamProvider.overrideWith((ref) => Stream.value([user])),
        userRoleProvider.overrideWith((ref) => UserRole.admin),
      ];

      testWidgets('con datos no produce overflow y el listado scrollea', (
        tester,
      ) async {
        await pumpInShell(
          tester,
          size: const Size(360, 640),
          scope: ProviderScope(
            overrides: [
              ...overrides,
              filteredMedicalDocumentsProvider.overrideWith((ref) => [doc]),
            ],
            child: buildShellApp(
              path: RoutePaths.medicalDocuments,
              screen: const MedicalDocumentsScreen(),
            ),
          ),
        );

        expect(tester.takeException(), isNull);

        await tester.scrollUntilVisible(
          find.byType(MedicalDocumentCard),
          400,
          maxScrolls: 30,
          scrollable: find.byType(Scrollable).first,
        );
        await tester.pumpAndSettle();
        expect(tester.takeException(), isNull);
        expect(find.byType(MedicalDocumentCard), findsWidgets);
      });

      testWidgets(
        'con datos y pantalla muy baja (360x568) no produce overflow',
        (tester) async {
          await pumpInShell(
            tester,
            size: const Size(360, 568),
            scope: ProviderScope(
              overrides: [
                ...overrides,
                filteredMedicalDocumentsProvider.overrideWith((ref) => [doc]),
              ],
              child: buildShellApp(
                path: RoutePaths.medicalDocuments,
                screen: const MedicalDocumentsScreen(),
              ),
            ),
          );

          expect(tester.takeException(), isNull);

          await tester.scrollUntilVisible(
            find.byType(MedicalDocumentCard),
            400,
            maxScrolls: 30,
            scrollable: find.byType(Scrollable).first,
          );
          await tester.pumpAndSettle();
          expect(tester.takeException(), isNull);
        },
      );

      testWidgets('sin datos el estado vacío es alcanzable scrolleando', (
        tester,
      ) async {
        await pumpInShell(
          tester,
          size: const Size(360, 640),
          scope: ProviderScope(
            overrides: overrides,
            child: buildShellApp(
              path: RoutePaths.medicalDocuments,
              screen: const MedicalDocumentsScreen(),
            ),
          ),
        );

        expect(tester.takeException(), isNull);

        await tester.scrollUntilVisible(
          find.text('Sin documentos médicos'),
          300,
          maxScrolls: 30,
          scrollable: find.byType(Scrollable).first,
        );
        await tester.pumpAndSettle();
        expect(tester.takeException(), isNull);
        expect(find.text('Sin documentos médicos'), findsOneWidget);
      });
    },
  );
}
