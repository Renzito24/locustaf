import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';

import 'package:app_locustaf/core/providers/data_providers.dart';
import 'package:app_locustaf/features/workplaces/data/models/workplace_model.dart';
import 'package:app_locustaf/features/workplaces/presentation/screens/workplace_form_screen.dart';

void main() {
  Widget buildApp(WorkplaceModel? initialData) {
    final router = GoRouter(
      initialLocation: '/',
      routes: [
        GoRoute(
          path: '/',
          builder: (context, state) => const Scaffold(
            body: WorkplaceFormScreen(),
          ),
        ),
      ],
      initialExtra: initialData,
    );

    return ProviderScope(
      overrides: [
        currentCompanyIdProvider.overrideWithValue('c1'),
      ],
      child: MaterialApp.router(
        routerConfig: router,
      ),
    );
  }

  testWidgets('renders create mode correctly', (tester) async {
    tester.view.physicalSize = const Size(1200, 2200);
    tester.view.devicePixelRatio = 1.0;

    await tester.pumpWidget(buildApp(null));
    await tester.pumpAndSettle();

    expect(find.text('Nuevo lugar de trabajo'), findsOneWidget);
    expect(find.text('Crear lugar de trabajo'), findsOneWidget);
    expect(find.byType(TextFormField), findsWidgets);
    
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
  });

  testWidgets('renders edit mode correctly', (tester) async {
    tester.view.physicalSize = const Size(1200, 2200);
    tester.view.devicePixelRatio = 1.0;

    final workplace = WorkplaceModel(
      id: 'wp1',
      nombre: 'Oficina Central',
      description: 'Sede principal',
      direccion: 'Av. Corrientes 123',
      latitud: -34.6037,
      longitud: -58.3816,
      radio: 100,
      codigo: 'OF-A',
      horaInicio: '08:00',
      horaFin: '17:00',
      toleranciaMinutos: 15,
      isActive: true,
      companyId: 'c1',
      createdAt: DateTime.now(),
    );

    await tester.pumpWidget(buildApp(workplace));
    await tester.pumpAndSettle();

    expect(find.text('Editar lugar de trabajo'), findsOneWidget);
    expect(find.text('Guardar cambios'), findsOneWidget);
    expect(find.text('Oficina Central'), findsOneWidget);

    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
  });
}
