import 'package:app_locustaf/core/models/company_model.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  final fixedNow = DateTime(2026, 9, 9, 12);

  CompanyModel build({
    CompanyEstado estado = CompanyEstado.activa,
    DateTime? paidUntil,
    CompanyPlan plan = CompanyPlan.mensual,
  }) {
    return CompanyModel(
      id: 'emp-1',
      nombreComercial: 'Locustaf SA',
      razonSocial: 'Locustaf SA',
      cuit: '30-12345678-9',
      estado: estado,
      createdAt: DateTime(2026, 1, 1),
      plan: plan,
      paidUntil: paidUntil,
      lastPaymentAt: paidUntil?.subtract(const Duration(days: 30)),
    );
  }

  group('CompanyModel (TASK-010) — suscripción', () {
    test('fromJson soporta docs legacy sin plan/paidUntil (no revienta)', () {
      final legacy = {
        'id': 'emp-x',
        'nombreComercial': 'Legacy',
        'razonSocial': 'Legacy',
        'cuit': '20-00000000-0',
        'estado': 'activa',
        'createdAt': '2026-01-01T11:00:00.000Z',
        'toleranciaCheckIn': 15,
        'diasLaborables': [1, 2, 3, 4, 5],
      };

      final model = CompanyModel.fromJson(legacy);

      expect(model.plan, CompanyPlan.mensual);
      expect(model.paidUntil, isNull);
      expect(model.lastPaymentAt, isNull);
      expect(model.isUsable, isTrue);
    });

    test('fromJson/toJson redondean plan, paidUntil y lastPaymentAt', () {
      final model = build(
        plan: CompanyPlan.anual,
        paidUntil: DateTime(2027, 9, 9),
      );

      final restored = CompanyModel.fromJson(model.toJson());

      expect(restored.plan, CompanyPlan.anual);
      expect(restored.paidUntil!.year, 2027);
      expect(restored.lastPaymentAt, isNotNull);
      expect(restored.estado, CompanyEstado.activa);
    });

    test('plan inválido lanza ArgumentError', () {
      expect(
        () => CompanyPlanExtension.fromString('premium'),
        throwsArgumentError,
      );
    });

    test('isUsableAt: activa y dentro de la fecha tope es usable', () {
      final model = build(paidUntil: fixedNow.add(const Duration(days: 10)));
      expect(model.isUsableAt(fixedNow), isTrue);
    });

    test('isUsableAt: vencida por paidUntil queda bloqueada aunque esté activa', () {
      final model = build(paidUntil: fixedNow.subtract(const Duration(days: 1)));
      expect(model.isUsableAt(fixedNow), isFalse);
    });

    test('isUsableAt: exactamente en el límite (paidUntil == now) no es usable', () {
      final model = build(paidUntil: fixedNow);
      expect(model.isUsableAt(fixedNow), isFalse);
    });

    test('isUsableAt: empresa inactiva manualmente no es usable aunque no venció', () {
      final model = build(
        estado: CompanyEstado.inactiva,
        paidUntil: fixedNow.add(const Duration(days: 10)),
      );
      expect(model.isUsableAt(fixedNow), isFalse);
    });

    test('isUsableAt: sin paidUntil (trial/legacy) es usable', () {
      final model = build(paidUntil: null);
      expect(model.isUsableAt(fixedNow), isTrue);
    });

    test('daysRemainingAt: días completos restantes', () {
      final model = build(paidUntil: fixedNow.add(const Duration(days: 5)));
      expect(model.daysRemainingAt(fixedNow), 5);
    });

    test('daysRemainingAt: vencida devuelve 0, sin tope devuelve 0', () {
      expect(
        build(paidUntil: fixedNow.subtract(const Duration(days: 3)))
            .daysRemainingAt(fixedNow),
        0,
      );
      expect(build(paidUntil: null).daysRemainingAt(fixedNow), 0);
    });

    test('copyWith no altera los campos de suscripción cuando no se pasan', () {
      final model = build(paidUntil: fixedNow);
      final copy = model.copyWith(nombreComercial: 'Nuevo');
      expect(copy.plan, model.plan);
      expect(copy.paidUntil, model.paidUntil);
      expect(copy.lastPaymentAt, model.lastPaymentAt);
    });

    test('CompanyPlanExtension.label mapea mensual/anual', () {
      expect(CompanyPlan.mensual.label, 'Mensual');
      expect(CompanyPlan.anual.label, 'Anual');
    });
  });
}