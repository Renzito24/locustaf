import 'package:app_locustaf/core/models/company_model.dart';
import 'package:app_locustaf/core/models/payment_model.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('PaymentModel (TASK-017)', () {
    test('fromJson/toJson redondean todos los campos incluyendo registradoPor',
        () {
      final payment = PaymentModel(
        id: 'pay-1',
        companyId: 'emp-1',
        companyName: 'Locustaf SA',
        plan: CompanyPlan.anual,
        paidUntil: DateTime(2027, 9, 9),
        nota: 'Renovación anual',
        createdAt: DateTime(2026, 9, 9, 12),
        registradoPor: 'uid-superadmin-123',
      );

      final restored = PaymentModel.fromJson(payment.toJson());

      expect(restored.id, 'pay-1');
      expect(restored.companyId, 'emp-1');
      expect(restored.companyName, 'Locustaf SA');
      expect(restored.plan, CompanyPlan.anual);
      expect(restored.paidUntil, DateTime(2027, 9, 9));
      expect(restored.nota, 'Renovación anual');
      expect(restored.createdAt, DateTime(2026, 9, 9, 12));
      expect(restored.registradoPor, 'uid-superadmin-123');
    });

    test('nota opcional: sin nota el round-trip conserva null', () {
      final payment = PaymentModel.fromJson({
        'id': 'pay-2',
        'companyId': 'emp-2',
        'companyName': 'Empresa B',
        'plan': 'mensual',
        'paidUntil': '2026-10-01T00:00:00.000Z',
        'createdAt': '2026-09-01T00:00:00.000Z',
      });

      expect(payment.nota, isNull);
      expect(payment.plan, CompanyPlan.mensual);
    });

    // --- NUEVO ---
    test(
        'registradoPor es opcional: docs legacy sin campo no fallan al parsear',
        () {
      // Documento Firestore que no tiene el campo registradoPor
      // (registros anteriores al cambio de schema).
      final payment = PaymentModel.fromJson({
        'id': 'pay-legacy',
        'companyId': 'emp-legacy',
        'companyName': 'Empresa Legacy',
        'plan': 'mensual',
        'paidUntil': '2026-10-01T00:00:00.000Z',
        'createdAt': '2026-09-01T00:00:00.000Z',
        // Sin 'registradoPor'
      });

      expect(payment.registradoPor, isNull);
    });

    test('registradoPor se serializa y deserializa correctamente', () {
      const uid = 'superadmin-uid-xyz';
      final payment = PaymentModel(
        id: 'pay-4',
        companyId: 'emp-4',
        companyName: 'Empresa D',
        plan: CompanyPlan.mensual,
        paidUntil: DateTime(2026, 10, 29),
        createdAt: DateTime(2026, 9, 29),
        registradoPor: uid,
      );

      final json = payment.toJson();
      expect(json['registradoPor'], uid);

      final restored = PaymentModel.fromJson({...json, 'id': payment.id});
      expect(restored.registradoPor, uid);
    });

    test('plan legacy o ausente degrada a mensual sin reventar', () {
      final payment = PaymentModel.fromJson({
        'id': 'pay-3',
        'companyId': 'emp-3',
        'companyName': 'Empresa C',
        'plan': 'premium-invalid',
        'paidUntil': '2026-10-01T00:00:00.000Z',
        'createdAt': '2026-09-01T00:00:00.000Z',
      });

      expect(payment.plan, CompanyPlan.mensual);
    });

    test('equatable: igualdad por valor (mismo registradoPor)', () {
      final a = PaymentModel(
        id: 'pay-1',
        companyId: 'emp-1',
        companyName: 'Locustaf SA',
        plan: CompanyPlan.mensual,
        paidUntil: DateTime(2026, 10, 1),
        createdAt: DateTime(2026, 9, 1),
        registradoPor: 'uid-123',
      );
      final b = PaymentModel(
        id: 'pay-1',
        companyId: 'emp-1',
        companyName: 'Locustaf SA',
        plan: CompanyPlan.mensual,
        paidUntil: DateTime(2026, 10, 1),
        createdAt: DateTime(2026, 9, 1),
        registradoPor: 'uid-123',
      );
      final c = PaymentModel(
        id: 'pay-1',
        companyId: 'emp-1',
        companyName: 'Locustaf SA',
        plan: CompanyPlan.mensual,
        paidUntil: DateTime(2026, 10, 1),
        createdAt: DateTime(2026, 9, 1),
        registradoPor: 'uid-DIFERENTE',
      );

      expect(a, equals(b));
      expect(a, isNot(equals(c)));
    });
  });
}