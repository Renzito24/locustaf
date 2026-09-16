import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:app_locustaf/core/constants/app_colors.dart';
import 'package:app_locustaf/core/theme/app_theme.dart';
import 'package:app_locustaf/core/widgets/metric_cards.dart';

/// Regression test Fase B (B1/B2): la grilla de métricas NO debe generar
/// BOTTOM OVERFLOWED en pantallas angostas de Android. La causa previa era el
/// `GridView.count` con `childAspectRatio` fijo dentro de una `Column` no
/// scrolleable; la nueva `MetricCardsGrid` usa `Wrap` con altura intrínseca.
void main() {
  const cards = [
    MetricCardData(
      icon: Icons.description,
      label: 'Total documentos',
      value: '12',
      color: AppColors.gold,
    ),
    MetricCardData(
      icon: Icons.check_circle,
      label: 'Vigentes',
      value: '8',
      color: AppColors.success,
    ),
    MetricCardData(
      icon: Icons.warning,
      label: 'Próximo a vencer',
      value: '3',
      color: AppColors.warning,
    ),
    MetricCardData(
      icon: Icons.cancel,
      label: 'Vencidos',
      value: '1',
      color: AppColors.error,
    ),
  ];

  Widget buildSut() {
    return MaterialApp(
      theme: AppTheme.light,
      home: const Scaffold(
        body: Column(
          children: [
            Padding(
              padding: EdgeInsets.all(24),
              child: MetricCardsGrid(cards: cards),
            ),
            Expanded(child: SizedBox()),
          ],
        ),
      ),
    );
  }

  Future<void> pumpAtSize(WidgetTester tester, Size size) async {
    tester.view.physicalSize = size;
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await tester.pumpWidget(buildSut());
    await tester.pump();
  }

  testWidgets('ancho reducido (360x640) no desborda', (tester) async {
    await pumpAtSize(tester, const Size(360, 640));
    expect(tester.takeException(), isNull,
        reason: 'no debería haber BOTTOM OVERFLOWED en 360px de ancho');
  });

  testWidgets('ancho muy reducido (320x568) no desborda', (tester) async {
    await pumpAtSize(tester, const Size(320, 568));
    expect(tester.takeException(), isNull);
  });

  testWidgets('dos columnas (600x800) no desborda', (tester) async {
    await pumpAtSize(tester, const Size(600, 800));
    expect(tester.takeException(), isNull);
  });

  testWidgets('cuatro columnas (900x700) no desborda', (tester) async {
    await pumpAtSize(tester, const Size(900, 700));
    expect(tester.takeException(), isNull);
  });

  testWidgets('una columna: las 4 tarjetas se muestran (sin ocultar contenido)',
      (tester) async {
    await pumpAtSize(tester, const Size(360, 1000));
    expect(find.text('Total documentos'), findsOneWidget);
    expect(find.text('Vigentes'), findsOneWidget);
    expect(find.text('Próximo a vencer'), findsOneWidget);
    expect(find.text('Vencidos'), findsOneWidget);
  });
}