import 'package:app_locustaf/core/models/company_model.dart';
import 'package:app_locustaf/core/providers/firebase_providers.dart';
import 'package:app_locustaf/core/services/firestore_service.dart';
import 'package:app_locustaf/features/companies/presentation/widgets/register_payment_dialog.dart';
import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

/// E2E de UI del registro de pago (superadmin, TASK-011/017): el diálogo
/// calcula el nuevo `paidUntil`, y el repo commitea en un batch la empresa +
/// el histórico. Verifica el resultado visible y la persistencia en Firestore
/// fake (sin emulador ni red).
void main() {
  const companyId = 'company-1';
  late FakeFirebaseFirestore fake;

  setUp(() {
    fake = FakeFirebaseFirestore();
  });

  Future<void> pumpDialog(WidgetTester tester, {DateTime? paidUntil}) async {
    tester.view.physicalSize = const Size(800, 1400);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final company = CompanyModel(
      id: companyId,
      nombreComercial: 'ACME SA',
      razonSocial: 'ACME SA',
      cuit: '30-12345678-9',
      createdAt: DateTime.now(),
      plan: CompanyPlan.mensual,
      paidUntil: paidUntil,
    );

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          firestoreServiceProvider
              .overrideWithValue(FirestoreService(fake)),
        ],
        child: MaterialApp(
          home: Scaffold(
            body: Builder(
              builder: (context) => Center(
                child: ElevatedButton(
                  onPressed: () => showDialog<void>(
                    context: context,
                    builder: (_) =>
                        RegisterPaymentDialog(company: company),
                  ),
                  child: const Text('abrir'),
                ),
              ),
            ),
          ),
        ),
      ),
    );
    await tester.tap(find.text('abrir'));
    await tester.pumpAndSettle();
  }

  testWidgets('registrar pago +1 mes: actualiza empresa y crea histórico en batch',
      (tester) async {
    await fake.collection('companies').doc(companyId).set({
      'id': companyId,
      'nombreComercial': 'ACME SA',
      'razonSocial': 'ACME SA',
      'cuit': '30-12345678-9',
      'estado': 'activa',
      'createdAt': DateTime.now().toIso8601String(),
    });

    await pumpDialog(tester);

    expect(find.text('Registrar pago'), findsOneWidget);
    expect(find.textContaining('Nuevo paidUntil'), findsOneWidget);

    await tester.tap(find.text('Registrar'));
    await tester.pumpAndSettle();

    final companyDoc = await fake.collection('companies').doc(companyId).get();
    final now = DateTime.now();
    final expected = DateTime(now.year, now.month + 1, now.day);

    final paidUntilRaw = companyDoc.get('paidUntil') as String;
    final paidUntil = DateTime.parse(paidUntilRaw).toLocal();
    expect(
      [paidUntil.year, paidUntil.month, paidUntil.day],
      [expected.year, expected.month, expected.day],
      reason: 'paidUntil debe extenderse +1 mes desde hoy',
    );
    expect(companyDoc.get('plan'), 'mensual');
    expect(companyDoc.get('lastPaymentAt'), isNotNull);

    final payments = await fake.collection('payments').get();
    expect(payments.docs, hasLength(1));
    expect(payments.docs.first.get('companyId'), companyId);
    expect(payments.docs.first.get('companyName'), 'ACME SA');
    expect(payments.docs.first.get('plan'), 'mensual');
    expect(payments.docs.first.get('paidUntil'), isNotNull);
  });

  testWidgets('registrar pago a partir de paidUntil vigente: acumula no solapa', (tester) async {
    final now = DateTime.now();
    final vigente = DateTime(now.year, now.month + 1, 10);
    await fake.collection('companies').doc(companyId).set({
      'id': companyId,
      'nombreComercial': 'ACME SA',
      'razonSocial': 'ACME SA',
      'cuit': '30-12345678-9',
      'estado': 'activa',
      'createdAt': DateTime.now().toIso8601String(),
      'paidUntil': vigente.toUtc().toIso8601String(),
      'plan': 'mensual',
    });

    await pumpDialog(tester, paidUntil: vigente);
    await tester.tap(find.text('Registrar'));
    await tester.pumpAndSettle();

    final companyDoc = await fake.collection('companies').doc(companyId).get();
    final stored = DateTime.parse(companyDoc.get('paidUntil') as String).toLocal();
    final expected = DateTime(vigente.year, vigente.month + 1, vigente.day);
    expect(
      [stored.year, stored.month, stored.day],
      [expected.year, expected.month, expected.day],
      reason: 'debe extenderse a partir del paidUntil vigente (no de hoy)',
    );
  });
}